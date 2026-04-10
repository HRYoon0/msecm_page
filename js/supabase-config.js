// MSECM Supabase 설정
const SUPABASE_URL = 'https://vnddtelgpnptjcdhhqxh.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_wgNyOeT9m0e4j_Vy1_NAeQ_1Hj3t4cG';

// Supabase 클라이언트 초기화
const { createClient } = supabase;
const db = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// ============ 공통 인증 함수 ============

// 학생 로그인 (닉네임 기반)
async function studentLogin(nickname, school = '') {
  // 기존 사용자 확인
  let { data: user } = await db
    .from('users')
    .select('*')
    .eq('nickname', nickname)
    .eq('role', 'student')
    .maybeSingle();

  // 없으면 자동 생성
  if (!user) {
    const { data: newUser, error } = await db
      .from('users')
      .insert({ nickname, school, role: 'student' })
      .select()
      .single();
    if (error) throw error;
    user = newUser;
  }

  localStorage.setItem('msecm_user', JSON.stringify(user));
  return user;
}

// 강사 로그인
async function instructorLogin(nickname, password) {
  const { data: user } = await db
    .from('users')
    .select('*')
    .eq('nickname', nickname)
    .eq('password', password)
    .eq('role', 'instructor')
    .maybeSingle();

  if (!user) throw new Error('강사명 또는 비밀번호가 올바르지 않습니다.');
  localStorage.setItem('msecm_instructor', JSON.stringify(user));
  return user;
}

// 현재 로그인 사용자 가져오기
function getCurrentUser() {
  const stored = localStorage.getItem('msecm_user');
  return stored ? JSON.parse(stored) : null;
}

function getCurrentInstructor() {
  const stored = localStorage.getItem('msecm_instructor');
  return stored ? JSON.parse(stored) : null;
}

// 로그아웃
function logout() {
  localStorage.removeItem('msecm_user');
  location.reload();
}

function instructorLogout() {
  localStorage.removeItem('msecm_instructor');
  location.reload();
}

// ============ 포트폴리오 함수 ============

async function getPrograms() {
  const { data } = await db.from('programs').select('*').order('id');
  return data || [];
}

async function joinProgram(userId, programId) {
  const { data, error } = await db
    .from('user_programs')
    .upsert({ user_id: userId, program_id: programId }, { onConflict: 'user_id,program_id' })
    .select();
  return { data, error };
}

async function getUserPrograms(userId) {
  const { data } = await db
    .from('user_programs')
    .select('*, programs(*)')
    .eq('user_id', userId);
  return data || [];
}

async function addPortfolioEntry(userId, programId, title, content, entryType = 'record', fileName = '', fileUrl = '') {
  const { data, error } = await db
    .from('portfolio_entries')
    .insert({ user_id: userId, program_id: programId, title, content, entry_type: entryType, file_name: fileName, file_url: fileUrl })
    .select();
  if (error) throw error;
  await checkAndAwardBadges(userId);
  return data;
}

async function getPortfolioEntries(userId, programId = null) {
  let query = db.from('portfolio_entries').select('*').eq('user_id', userId).order('created_at', { ascending: false });
  if (programId) query = query.eq('program_id', programId);
  const { data } = await query;
  return data || [];
}

async function deletePortfolioEntry(entryId) {
  await db.from('portfolio_entries').delete().eq('id', entryId);
}

// ============ 뱃지 함수 ============

async function getBadges() {
  const { data } = await db.from('badges').select('*').order('id');
  return data || [];
}

async function getUserBadges(userId) {
  const { data } = await db.from('user_badges').select('*, badges(*)').eq('user_id', userId);
  return data || [];
}

async function checkAndAwardBadges(userId) {
  const badges = await getBadges();
  const userBadges = await getUserBadges(userId);
  const earnedIds = userBadges.map(ub => ub.badge_id);

  // 통계 수집
  const { count: totalRecords } = await db.from('portfolio_entries').select('*', { count: 'exact', head: true }).eq('user_id', userId).eq('entry_type', 'record');
  const { count: totalUploads } = await db.from('portfolio_entries').select('*', { count: 'exact', head: true }).eq('user_id', userId).eq('entry_type', 'upload');
  const { data: userProgs } = await db.from('user_programs').select('*').eq('user_id', userId);
  const programsJoined = userProgs ? userProgs.length : 0;
  const programsCompleted = userProgs ? userProgs.filter(p => p.status === 'completed').length : 0;

  const newBadges = [];

  for (const badge of badges) {
    if (earnedIds.includes(badge.id)) continue;

    let earned = false;
    switch (badge.condition_type) {
      case 'total_records': earned = totalRecords >= badge.condition_value; break;
      case 'total_uploads': earned = totalUploads >= badge.condition_value; break;
      case 'programs_joined': earned = programsJoined >= badge.condition_value; break;
      case 'programs_completed': earned = programsCompleted >= badge.condition_value; break;
      case 'specific_program': earned = userProgs?.some(p => p.program_id === badge.condition_value); break;
    }

    if (earned) {
      await db.from('user_badges').insert({ user_id: userId, badge_id: badge.id });
      await addNotification(userId, `새 뱃지를 획득했습니다: ${badge.emoji} ${badge.name}`, 'badge');
      newBadges.push(badge);
    }
  }

  return newBadges;
}

// ============ 알림 함수 ============

async function addNotification(userId, message, type = 'info') {
  await db.from('notifications').insert({ user_id: userId, message, type });
}

async function getNotifications(userId) {
  const { data } = await db.from('notifications').select('*').eq('user_id', userId).order('created_at', { ascending: false }).limit(20);
  return data || [];
}

async function markNotificationRead(notifId) {
  await db.from('notifications').update({ is_read: true }).eq('id', notifId);
}

async function getUnreadCount(userId) {
  const { count } = await db.from('notifications').select('*', { count: 'exact', head: true }).eq('user_id', userId).eq('is_read', false);
  return count || 0;
}

// ============ 자료실 함수 ============

async function getResources(filters = {}) {
  let query = db.from('resources').select('*').order('created_at', { ascending: false });
  if (filters.category && filters.category !== '전체') query = query.eq('category', filters.category);
  if (filters.subject && filters.subject !== '전체') query = query.eq('subject', filters.subject);
  if (filters.search) query = query.ilike('title', `%${filters.search}%`);
  if (filters.sort === '인기순') query = query.order('download_count', { ascending: false });
  if (filters.sort === '이름순') query = query.order('title');
  const { data } = await query;
  return data || [];
}

async function addResource(resource) {
  const { data, error } = await db.from('resources').insert(resource).select();
  if (error) throw error;
  return data;
}

async function incrementDownload(resourceId) {
  await db.rpc('increment_download', { resource_id: resourceId }).catch(() => {
    // rpc가 없으면 직접 업데이트
    db.from('resources').select('download_count').eq('id', resourceId).single().then(({ data }) => {
      if (data) db.from('resources').update({ download_count: data.download_count + 1 }).eq('id', resourceId);
    });
  });
}

// ============ 원격 연수원 함수 ============

async function getCourses(category = null) {
  let query = db.from('courses').select('*').order('student_count', { ascending: false });
  if (category && category !== '전체') query = query.eq('category', category);
  const { data } = await query;
  return data || [];
}

async function enrollCourse(userId, courseId) {
  const { data, error } = await db
    .from('course_enrollments')
    .upsert({ user_id: userId, course_id: courseId }, { onConflict: 'user_id,course_id' })
    .select();
  // 수강생 수 증가
  if (!error) {
    const { data: course } = await db.from('courses').select('student_count').eq('id', courseId).single();
    if (course) await db.from('courses').update({ student_count: course.student_count + 1 }).eq('id', courseId);
  }
  return { data, error };
}

async function getUserEnrollments(userId) {
  const { data } = await db
    .from('course_enrollments')
    .select('*, courses(*)')
    .eq('user_id', userId);
  return data || [];
}

async function updateLessonProgress(enrollmentId, completedLessons) {
  const { data } = await db
    .from('course_enrollments')
    .update({ completed_lessons: completedLessons })
    .eq('id', enrollmentId)
    .select('*, courses(*)');
  return data?.[0];
}

async function completeCourse(enrollmentId) {
  await db.from('course_enrollments').update({ status: 'completed' }).eq('id', enrollmentId);
}

// ============ 유틸리티 ============

function formatDate(dateStr) {
  const d = new Date(dateStr);
  return `${d.getFullYear()}.${String(d.getMonth() + 1).padStart(2, '0')}.${String(d.getDate()).padStart(2, '0')}`;
}

function timeAgo(dateStr) {
  const now = new Date();
  const d = new Date(dateStr);
  const diff = Math.floor((now - d) / 1000);
  if (diff < 60) return '방금 전';
  if (diff < 3600) return `${Math.floor(diff / 60)}분 전`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}시간 전`;
  return `${Math.floor(diff / 86400)}일 전`;
}
