-- ============================================
-- MSECM 디지털 교육 플랫폼 — Supabase 스키마
-- ============================================

-- 1. 사용자 테이블
CREATE TABLE users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nickname TEXT NOT NULL,
  school TEXT DEFAULT '',
  password TEXT DEFAULT '1234',
  role TEXT DEFAULT 'student' CHECK (role IN ('student', 'instructor', 'admin')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 기본 강사 계정 삽입
INSERT INTO users (nickname, password, role) VALUES
  ('MSECM', '1234', 'instructor'),
  ('홍길동', '1234', 'instructor');

-- 2. 프로그램 마스터 테이블
CREATE TABLE programs (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  icon TEXT DEFAULT 'solar:book-bold',
  difficulty TEXT DEFAULT '기초' CHECK (difficulty IN ('기초', '중급', '심화')),
  category TEXT DEFAULT '공통',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO programs (title, description, icon, difficulty, category) VALUES
  ('디지털 리터러시 기초', '디지털 도구의 기본 활용법과 온라인 안전을 학습합니다.', 'solar:monitor-smartphone-bold', '기초', '공통'),
  ('AI 활용 학습법', '생성형 AI를 수업과 학습에 효과적으로 활용하는 방법을 배웁니다.', 'solar:cpu-bolt-bold', '중급', 'AI·디지털'),
  ('코딩 & 바이브코딩', '바이브코딩과 앱스스크립트를 활용한 교육용 앱 제작을 학습합니다.', 'solar:code-bold', '중급', '정보'),
  ('데이터 분석 입문', 'CODAP, 구글 시트를 활용한 데이터 분석과 시각화를 학습합니다.', 'solar:chart-2-bold', '기초', '수학'),
  ('디지털 콘텐츠 제작', '캔바, 구글 사이트 등을 활용한 교육 콘텐츠 제작법을 배웁니다.', 'solar:palette-bold', '기초', '공통'),
  ('글로벌 의사소통', '디지털 도구를 활용한 글로벌 협업과 의사소통 역량을 키웁니다.', 'solar:global-bold', '심화', '영어');

-- 3. 포트폴리오 기록 테이블
CREATE TABLE portfolio_entries (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  program_id INTEGER REFERENCES programs(id),
  title TEXT NOT NULL,
  content TEXT,
  file_name TEXT,
  file_url TEXT,
  entry_type TEXT DEFAULT 'record' CHECK (entry_type IN ('record', 'upload')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. 뱃지 마스터 테이블
CREATE TABLE badges (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  emoji TEXT NOT NULL,
  description TEXT,
  condition_type TEXT NOT NULL,
  condition_value INTEGER DEFAULT 1
);

INSERT INTO badges (name, emoji, description, condition_type, condition_value) VALUES
  ('첫 발걸음', '🌟', '첫 번째 기록을 작성했습니다.', 'total_records', 1),
  ('꾸준한 학습자', '📝', '기록을 5개 이상 작성했습니다.', 'total_records', 5),
  ('창작의 달인', '🎨', '산출물을 3개 이상 업로드했습니다.', 'total_uploads', 3),
  ('프로그램 완주', '🏆', '프로그램 1개를 완료했습니다.', 'programs_completed', 1),
  ('글로벌 리더', '🌍', '글로벌 의사소통 프로그램에 참여했습니다.', 'specific_program', 6),
  ('아이디어 뱅크', '💡', '기록을 10개 이상 작성했습니다.', 'total_records', 10),
  ('열정의 아이콘', '🔥', '3개 이상 프로그램에 참여했습니다.', 'programs_joined', 3),
  ('올라운더', '⭐', '전체 프로그램에 참여했습니다.', 'programs_joined', 6);

-- 5. 사용자 뱃지 획득 테이블
CREATE TABLE user_badges (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  badge_id INTEGER REFERENCES badges(id),
  earned_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, badge_id)
);

-- 6. 사용자 프로그램 참여 테이블
CREATE TABLE user_programs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  program_id INTEGER REFERENCES programs(id),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed')),
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, program_id)
);

-- 7. 교육자료 테이블
CREATE TABLE resources (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT DEFAULT '참고자료',
  subject TEXT DEFAULT '전체',
  file_type TEXT DEFAULT 'PDF',
  file_url TEXT,
  file_size TEXT DEFAULT '',
  download_count INTEGER DEFAULT 0,
  uploaded_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO resources (title, description, category, subject, file_type, file_size, download_count) VALUES
  ('디지털 기반 수업 설계 가이드', '디지털 도구를 활용한 수업 설계의 기본 원칙과 실제 사례를 정리한 가이드입니다.', '참고자료', '초등', 'PDF', '4.2MB', 128),
  ('캔바 AI 활용 수업자료 제작법', '캔바의 AI 기능을 활용하여 효과적인 수업 자료를 제작하는 방법을 안내합니다.', '수업지도안', '초등', 'PPT', '8.1MB', 95),
  ('알지오매스 블록코딩 활동지', '알지오매스의 블록코딩 기능을 활용한 수학 탐구 활동지입니다.', '활동지', '중등-수학', 'HWP', '2.3MB', 67),
  ('Desmos 수학 수업 활용 매뉴얼', 'Desmos 그래핑 계산기와 Polypad를 수업에 활용하는 종합 매뉴얼입니다.', '참고자료', '중등-수학', 'PDF', '5.6MB', 143),
  ('생성형 AI 영어 수업 프롬프트 모음', '제미나이, ChatGPT 등을 영어 수업에 활용하기 위한 프롬프트 모음집입니다.', '참고자료', '중등-영어', 'PDF', '3.1MB', 201),
  ('구글 사이트 활용 수업교실 만들기', '구글 사이트를 활용하여 나만의 온라인 수업 교실을 구축하는 영상 튜토리얼입니다.', '영상', '초등', 'MP4', '156MB', 89),
  ('NotebookLM 교육과정 비서 활용법', 'Google NotebookLM을 활용하여 교육과정 분석 도우미를 만드는 방법을 안내합니다.', '수업지도안', '중등-정보', 'PPT', '6.4MB', 112),
  ('Apps Script 웹앱 개발 튜토리얼', 'Google Apps Script를 활용한 교육용 웹 앱 개발 단계별 튜토리얼입니다.', '참고자료', '중등-정보', 'PDF', '7.8MB', 76),
  ('바이브코딩 입문 가이드', '바이브코딩의 개념과 제미나이 Canvas를 활용한 실습 가이드입니다.', '참고자료', '중등-정보', 'PDF', '4.5MB', 158),
  ('CODAP 데이터 분석 활동지', 'CODAP을 활용한 데이터 수집, 분석, 시각화 활동지입니다.', '활동지', '중등-수학', 'HWP', '1.8MB', 54),
  ('디지털 수업 성찰 체크리스트', '디지털 기반 수업 후 교사 자기 성찰을 위한 체크리스트입니다.', '평가도구', '전체', 'PDF', '1.2MB', 187),
  ('에듀테크 도구 비교 분석표', '주요 에듀테크 도구 30종의 기능, 비용, 활용법을 비교 분석한 자료입니다.', '참고자료', '전체', 'PPT', '9.3MB', 234);

-- 8. 알림 테이블
CREATE TABLE notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  type TEXT DEFAULT 'info' CHECK (type IN ('info', 'badge', 'feedback', 'system')),
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. 원격 연수 강좌 테이블
CREATE TABLE courses (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  instructor TEXT DEFAULT 'MSECM',
  category TEXT DEFAULT '공통',
  difficulty TEXT DEFAULT '기초',
  total_lessons INTEGER DEFAULT 6,
  thumbnail_url TEXT,
  student_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO courses (title, description, instructor, category, difficulty, total_lessons, thumbnail_url, student_count) VALUES
  ('디지털 리터러시의 이해', '디지털 시대에 필요한 기본 역량과 도구 활용법을 학습합니다.', '김디지털', 'AI·디지털', '기초', 6, 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=400&h=250&fit=crop', 342),
  ('생성형 AI 수업 활용 마스터', '제미나이, ChatGPT를 수업에 효과적으로 활용하는 실전 과정입니다.', '이에이아이', 'AI·디지털', '중급', 8, 'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=400&h=250&fit=crop', 528),
  ('알지오매스로 배우는 수학', '알지오매스 블록코딩을 활용한 수학 수업 설계와 실습을 다룹니다.', '박수학', '수학', '중급', 6, 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=400&h=250&fit=crop', 187),
  ('Desmos & CODAP 데이터 수업', '데이터 분석 도구를 활용한 수학 수업 실습 과정입니다.', '최데이터', '수학', '기초', 5, 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=400&h=250&fit=crop', 156),
  ('디지털 영어 수업 디자인', '에듀테크 도구를 활용한 참여형 영어 수업을 설계합니다.', '정영어', '영어', '중급', 7, 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=400&h=250&fit=crop', 298),
  ('Apps Script 웹앱 만들기', 'Google Apps Script로 교육용 웹 앱을 개발하는 실전 과정입니다.', '한코딩', '정보', '심화', 10, 'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?w=400&h=250&fit=crop', 124),
  ('바이브코딩 완전정복', '제미나이 Canvas와 바이브코딩으로 수업 도구를 만드는 과정입니다.', '송바이브', '정보', '중급', 8, 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=400&h=250&fit=crop', 367),
  ('캔바로 수업자료 만들기', '캔바의 AI 기능을 활용한 시각적 수업 자료 제작 과정입니다.', '윤디자인', 'AI·디지털', '기초', 5, 'https://images.unsplash.com/photo-1611532736597-de2d4265fba3?w=400&h=250&fit=crop', 445);

-- 10. 수강 이력 테이블
CREATE TABLE course_enrollments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  course_id INTEGER REFERENCES courses(id),
  completed_lessons INTEGER DEFAULT 0,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed')),
  enrolled_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, course_id)
);

-- ============================================
-- RLS (Row Level Security) 정책
-- ============================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE portfolio_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_enrollments ENABLE ROW LEVEL SECURITY;

-- 모든 테이블에 anon 읽기 허용 (더미용 — 운영 시 수정 필요)
CREATE POLICY "Allow all read" ON users FOR SELECT USING (true);
CREATE POLICY "Allow all insert" ON users FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow all read" ON programs FOR SELECT USING (true);
CREATE POLICY "Allow all read" ON badges FOR SELECT USING (true);
CREATE POLICY "Allow all read" ON courses FOR SELECT USING (true);
CREATE POLICY "Allow all read" ON resources FOR SELECT USING (true);

CREATE POLICY "Allow all" ON portfolio_entries FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all" ON user_badges FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all" ON user_programs FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all" ON notifications FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all" ON course_enrollments FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow insert" ON resources FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow update" ON resources FOR UPDATE USING (true);
