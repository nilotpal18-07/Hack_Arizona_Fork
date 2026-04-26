-- Synthetic seed data: Cohort 43, 10 participants, 10 weeks
-- Participant trajectories:
--   Stable graduates       (1–3): Maria Chen, James Nguyen, Amara Osei
--   Recovered after intervention (4–6): Sofia Reyes, Derek Johnson, Linda Yazzie
--   High risk, graduated   (7–8): Carlos Mendez, Tanya Williams
--   Dropped out            (9–10): Marcus Hill (wk 6), Rosa Flores (wk 4)

-- ─── COHORT ──────────────────────────────────────────────────────────
INSERT INTO cohorts (cohort_number, start_date, end_date, max_capacity, status)
VALUES (43, '2026-04-07', '2026-06-13', 20, 'active');

-- ─── COORDINATORS ────────────────────────────────────────────────────
INSERT INTO coordinators (first_name, last_name, email, phone, role) VALUES
  ('Rosa',  'Mendez', 'rosa.mendez@communityfoodbank.org',  '5204991001', 'coordinator'),
  ('James', 'Okafor', 'james.okafor@communityfoodbank.org', '5204991002', 'supervisor');

-- ─── PARTICIPANTS ─────────────────────────────────────────────────────
INSERT INTO participants
  (cohort_id, first_name, last_name, phone, email,
   date_of_birth, enrollment_date, status, withdrawal_date, withdrawal_reason)
VALUES
  (1,'Maria',  'Chen',     '+15201110001','maria.chen@email.com',    '1994-06-15','2026-04-07','active', NULL,NULL),
  (1,'James',  'Nguyen',   '+15201110002','james.nguyen@email.com',  '1990-03-22','2026-04-07','active', NULL,NULL),
  (1,'Amara',  'Osei',     '+15201110003','amara.osei@email.com',    '1997-11-08','2026-04-07','active', NULL,NULL),
  (1,'Sofia',  'Reyes',    '+15201110004','sofia.reyes@email.com',   '1992-09-30','2026-04-07','active', NULL,NULL),
  (1,'Derek',  'Johnson',  '+15201110005','derek.johnson@email.com', '1986-04-17','2026-04-07','active', NULL,NULL),
  (1,'Linda',  'Yazzie',   '+15201110006','linda.yazzie@email.com',  '1993-01-25','2026-04-07','active', NULL,NULL),
  (1,'Carlos', 'Mendez',   '+15201110007','carlos.mendez@email.com', '1988-07-04','2026-04-07','active', NULL,NULL),
  (1,'Tanya',  'Williams', '+15201110008','tanya.williams@email.com','1991-12-19','2026-04-07','active', NULL,NULL),
  (1,'Marcus', 'Hill',     '+15201110009','marcus.hill@email.com',   '1985-08-11','2026-04-07','dropped',
   '2026-05-14','Stopped attending and responding after week 5'),
  (1,'Rosa',   'Flores',   '+15201110010','rosa.flores@email.com',   '1996-02-28','2026-04-07','dropped',
   '2026-04-30','Childcare and transportation barriers unresolved');

-- ─── BASELINE ASSESSMENTS ─────────────────────────────────────────────
INSERT INTO baseline_assessments
  (participant_id, cohort_id,
   primary_barrier, housing_status,
   has_reliable_transport, transport_mode,
   has_dependents, dependent_ages, childcare_arranged,
   financial_stress_score, stated_goal,
   prior_food_service, prior_food_service_years,
   has_support_network, contact_preference)
VALUES
  -- 1 Maria Chen: unemployment, stable, own car, no dependents
  (1,1,'unemployment','stable',TRUE,'own_vehicle',FALSE,NULL,NULL,2,
   'Land a kitchen job and start saving for culinary school',FALSE,NULL,TRUE,'sms'),
  -- 2 James Nguyen: long-term absence, stable, own car, prior experience
  (2,1,'long_term_absence','stable',TRUE,'own_vehicle',FALSE,NULL,NULL,2,
   'Re-enter the workforce and regain my confidence',TRUE,3,TRUE,'sms'),
  -- 3 Amara Osei: unemployment, stable, public transit, very motivated
  (3,1,'unemployment','stable',TRUE,'public_transit',FALSE,NULL,NULL,1,
   'Open my own catering business within 3 years',FALSE,NULL,TRUE,'sms'),
  -- 4 Sofia Reyes: unemployment, stable, own car, 2 young kids
  (4,1,'unemployment','stable',TRUE,'own_vehicle',TRUE,'2, 5',TRUE,3,
   'Build a stable career so my kids see me succeed',FALSE,NULL,TRUE,'sms'),
  -- 5 Derek Johnson: reentry, transitional housing, no support network
  (5,1,'reentry','transitional',TRUE,'own_vehicle',FALSE,NULL,NULL,3,
   'Get stable housing and a steady job I am proud of',FALSE,NULL,FALSE,'call'),
  -- 6 Linda Yazzie: unemployment, stable, public transit
  (6,1,'unemployment','stable',TRUE,'public_transit',FALSE,NULL,NULL,3,
   'Support my family and become financially independent',FALSE,NULL,TRUE,'sms'),
  -- 7 Carlos Mendez: reentry, unstable housing, no transport
  (7,1,'reentry','unstable',FALSE,'none',FALSE,NULL,NULL,4,
   'Prove to myself and my family that I can make it',FALSE,NULL,TRUE,'sms'),
  -- 8 Tanya Williams: long-term absence, unstable housing, no support network
  (8,1,'long_term_absence','unstable',TRUE,'public_transit',FALSE,NULL,NULL,4,
   'Get stable housing and build a life I can be proud of',FALSE,NULL,FALSE,'sms'),
  -- 9 Marcus Hill: reentry, transitional housing, no support network
  (9,1,'reentry','transitional',TRUE,'public_transit',FALSE,NULL,NULL,3,
   'Start fresh and show my kids a better path',FALSE,NULL,FALSE,'sms'),
  -- 10 Rosa Flores: unemployment, stable, public transit, 2 young kids
  (10,1,'unemployment','stable',TRUE,'public_transit',TRUE,'1, 3',TRUE,3,
   'Become a cook and be a role model for my children',FALSE,NULL,TRUE,'sms');

-- ─── WEEKLY CHECK-INS ─────────────────────────────────────────────────
-- 7 signals: transport, housing, childcare, financial, motivation, physical, overwhelmed
-- Scale 1–5 (5 = most severe / most stressed / least motivated)
-- no_reply = TRUE means participant did not respond to SMS that week
INSERT INTO weekly_checkins
  (participant_id, week_number, channel,
   transport_barrier, housing_barrier, childcare_barrier, financial_stress,
   motivation_score, physical_wellbeing, feeling_overwhelmed, no_reply)
VALUES
-- ── Maria Chen (1): stable throughout ────────────────────────────────
(1,1,'sms',1,1,1,2,5,4,1,FALSE),(1,2,'sms',1,1,1,2,5,4,1,FALSE),
(1,3,'sms',1,1,1,2,5,4,1,FALSE),(1,4,'sms',1,1,1,2,4,4,2,FALSE),
(1,5,'sms',1,1,1,2,5,4,1,FALSE),(1,6,'sms',1,1,1,2,5,5,1,FALSE),
(1,7,'sms',1,1,1,2,5,5,1,FALSE),(1,8,'sms',1,1,1,1,5,5,1,FALSE),
(1,9,'sms',1,1,1,1,5,5,1,FALSE),(1,10,'sms',1,1,1,1,5,5,1,FALSE),
-- ── James Nguyen (2): stable throughout ──────────────────────────────
(2,1,'sms',1,2,1,2,4,4,2,FALSE),(2,2,'sms',1,2,1,2,4,4,2,FALSE),
(2,3,'sms',1,2,1,2,4,4,2,FALSE),(2,4,'sms',1,2,1,2,4,4,2,FALSE),
(2,5,'sms',1,2,1,2,4,4,2,FALSE),(2,6,'sms',1,1,1,2,4,4,1,FALSE),
(2,7,'sms',1,1,1,2,4,5,1,FALSE),(2,8,'sms',1,1,1,1,4,5,1,FALSE),
(2,9,'sms',1,1,1,1,5,5,1,FALSE),(2,10,'sms',1,1,1,1,5,5,1,FALSE),
-- ── Amara Osei (3): very stable, highest motivation ───────────────────
(3,1,'sms',2,1,1,1,5,5,1,FALSE),(3,2,'sms',2,1,1,1,5,5,1,FALSE),
(3,3,'sms',2,1,1,1,5,5,1,FALSE),(3,4,'sms',2,1,1,1,5,5,1,FALSE),
(3,5,'sms',2,1,1,1,5,5,1,FALSE),(3,6,'sms',1,1,1,1,5,5,1,FALSE),
(3,7,'sms',1,1,1,1,5,5,1,FALSE),(3,8,'sms',1,1,1,1,5,5,1,FALSE),
(3,9,'sms',1,1,1,1,5,5,1,FALSE),(3,10,'sms',1,1,1,1,5,5,1,FALSE),
-- ── Sofia Reyes (4): childcare crisis wk 3–4, recovered wk 5+ ────────
(4,1,'sms',1,1,2,3,4,4,2,FALSE),
(4,2,'sms',1,1,3,3,4,3,3,FALSE),
(4,3,'sms',1,1,5,4,2,3,4,FALSE),   -- CRISIS: childcare 5, motivation 2
(4,4,'sms',1,1,4,4,3,3,3,FALSE),   -- still elevated
(4,5,'sms',1,1,2,2,4,4,2,FALSE),   -- RECOVERED after DES referral
(4,6,'sms',1,1,2,2,4,4,1,FALSE),(4,7,'sms',1,1,2,2,5,4,1,FALSE),
(4,8,'sms',1,1,1,2,5,5,1,FALSE),(4,9,'sms',1,1,1,1,5,5,1,FALSE),
(4,10,'sms',1,1,1,1,5,5,1,FALSE),
-- ── Derek Johnson (5): housing crisis wk 2–3, recovered wk 4+ ────────
(5,1,'sms',1,3,1,2,4,4,2,FALSE),
(5,2,'sms',1,4,1,3,3,3,3,FALSE),   -- housing escalating
(5,3,'sms',1,5,1,4,2,3,4,FALSE),   -- CRISIS: housing 5, motivation 2
(5,4,'sms',1,3,1,2,4,4,2,FALSE),   -- RECOVERED after Primavera referral
(5,5,'sms',1,2,1,2,4,4,1,FALSE),(5,6,'sms',1,2,1,2,4,4,1,FALSE),
(5,7,'sms',1,2,1,2,4,5,1,FALSE),(5,8,'sms',1,1,1,2,4,5,1,FALSE),
(5,9,'sms',1,1,1,1,5,5,1,FALSE),(5,10,'sms',1,1,1,1,5,5,1,FALSE),
-- ── Linda Yazzie (6): financial spike wk 5, recovered wk 6+ ──────────
(6,1,'sms',2,1,1,3,4,4,2,FALSE),(6,2,'sms',2,1,1,3,4,4,2,FALSE),
(6,3,'sms',2,1,1,3,4,4,2,FALSE),(6,4,'sms',2,1,1,3,4,4,2,FALSE),
(6,5,'sms',2,1,1,5,2,3,4,FALSE),   -- SPIKE: financial 5, motivation 2
(6,6,'sms',2,1,1,3,4,4,2,FALSE),   -- RECOVERED after motivational SMS
(6,7,'sms',2,1,1,2,4,4,2,FALSE),(6,8,'sms',2,1,1,2,4,4,1,FALSE),
(6,9,'sms',1,1,1,2,4,5,1,FALSE),(6,10,'sms',1,1,1,1,5,5,1,FALSE),
-- ── Carlos Mendez (7): persistently medium-high, transport + reentry ──
(7,1,'sms',5,3,1,4,4,3,3,FALSE),(7,2,'sms',5,3,1,4,4,3,4,FALSE),
(7,3,'sms',5,4,1,4,3,3,4,FALSE),(7,4,'sms',4,3,1,4,4,3,3,FALSE),
(7,5,'sms',5,3,1,4,4,3,3,FALSE),(7,6,'sms',4,3,1,3,4,3,3,FALSE),
(7,7,'sms',5,3,1,3,4,4,3,FALSE),(7,8,'sms',4,3,1,3,4,4,3,FALSE),
(7,9,'sms',4,3,1,3,4,4,2,FALSE),(7,10,'sms',4,2,1,3,5,4,2,FALSE),
-- ── Tanya Williams (8): persistently high, housing + no support ───────
(8,1,'sms',2,4,1,4,3,3,4,FALSE),(8,2,'sms',2,5,1,4,3,3,4,FALSE),
(8,3,'sms',2,5,1,4,2,3,4,FALSE),   -- motivation drops
(8,4,'sms',2,4,1,4,3,3,4,FALSE),(8,5,'sms',2,5,1,4,3,3,4,FALSE),
(8,6,'sms',2,4,1,3,3,3,3,FALSE),(8,7,'sms',2,4,1,3,3,4,3,FALSE),
(8,8,'sms',2,4,1,3,3,4,3,FALSE),(8,9,'sms',2,3,1,3,4,4,3,FALSE),
(8,10,'sms',2,3,1,3,4,4,2,FALSE),
-- ── Marcus Hill (9): no reply wk 4–5, dropped wk 6 ──────────────────
(9,1,'sms',2,2,1,3,4,4,2,FALSE),
(9,2,'sms',3,3,1,3,3,3,3,FALSE),
(9,3,'sms',4,3,1,4,3,3,3,FALSE),
(9,4,'sms',NULL,NULL,NULL,NULL,NULL,NULL,NULL,TRUE),  -- no reply
(9,5,'sms',NULL,NULL,NULL,NULL,NULL,NULL,NULL,TRUE),  -- no reply → trigger
-- ── Rosa Flores (10): childcare crisis wk 2, no reply wk 3, dropped ──
(10,1,'sms',3,1,4,3,4,4,3,FALSE),
(10,2,'sms',4,1,5,4,2,3,4,FALSE),  -- CRISIS: childcare 5, motivation 2
(10,3,'sms',NULL,NULL,NULL,NULL,NULL,NULL,NULL,TRUE); -- no reply

-- ─── CHAPTER CONFIDENCE CHECKS ────────────────────────────────────────
-- One chapter per week; Marcus has wk 1–5 only; Rosa has wk 1–2 only
INSERT INTO chapter_confidence_checks
  (participant_id, week_number, chapter_name, confidence_score)
VALUES
-- Maria Chen (1): consistently confident, ends strong
(1,1,'Knife Skills',4),(1,2,'Food Safety',4),(1,3,'Kitchen Sanitation',4),
(1,4,'Cooking Procedures',4),(1,5,'Food Utilization',5),(1,6,'Quantity Meal Preparation',4),
(1,7,'ServSafe Certification Prep',5),(1,8,'Advanced Cooking Techniques',4),
(1,9,'Practical Kitchen Experience',5),(1,10,'Job Readiness and Final Assessment',5),
-- James Nguyen (2): steady, improves over time
(2,1,'Knife Skills',3),(2,2,'Food Safety',3),(2,3,'Kitchen Sanitation',4),
(2,4,'Cooking Procedures',4),(2,5,'Food Utilization',4),(2,6,'Quantity Meal Preparation',4),
(2,7,'ServSafe Certification Prep',4),(2,8,'Advanced Cooking Techniques',4),
(2,9,'Practical Kitchen Experience',5),(2,10,'Job Readiness and Final Assessment',5),
-- Amara Osei (3): perfect confidence throughout
(3,1,'Knife Skills',5),(3,2,'Food Safety',5),(3,3,'Kitchen Sanitation',5),
(3,4,'Cooking Procedures',5),(3,5,'Food Utilization',5),(3,6,'Quantity Meal Preparation',5),
(3,7,'ServSafe Certification Prep',5),(3,8,'Advanced Cooking Techniques',5),
(3,9,'Practical Kitchen Experience',5),(3,10,'Job Readiness and Final Assessment',5),
-- Sofia Reyes (4): dips wk 3–4, recovers
(4,1,'Knife Skills',4),(4,2,'Food Safety',3),(4,3,'Kitchen Sanitation',2),
(4,4,'Cooking Procedures',2),(4,5,'Food Utilization',4),(4,6,'Quantity Meal Preparation',4),
(4,7,'ServSafe Certification Prep',4),(4,8,'Advanced Cooking Techniques',4),
(4,9,'Practical Kitchen Experience',4),(4,10,'Job Readiness and Final Assessment',5),
-- Derek Johnson (5): dips wk 2–3, recovers
(5,1,'Knife Skills',3),(5,2,'Food Safety',2),(5,3,'Kitchen Sanitation',2),
(5,4,'Cooking Procedures',4),(5,5,'Food Utilization',4),(5,6,'Quantity Meal Preparation',4),
(5,7,'ServSafe Certification Prep',4),(5,8,'Advanced Cooking Techniques',4),
(5,9,'Practical Kitchen Experience',5),(5,10,'Job Readiness and Final Assessment',4),
-- Linda Yazzie (6): dips wk 5, recovers
(6,1,'Knife Skills',4),(6,2,'Food Safety',4),(6,3,'Kitchen Sanitation',4),
(6,4,'Cooking Procedures',4),(6,5,'Food Utilization',2),(6,6,'Quantity Meal Preparation',4),
(6,7,'ServSafe Certification Prep',4),(6,8,'Advanced Cooking Techniques',4),
(6,9,'Practical Kitchen Experience',4),(6,10,'Job Readiness and Final Assessment',5),
-- Carlos Mendez (7): low-moderate, gradual improvement
(7,1,'Knife Skills',3),(7,2,'Food Safety',3),(7,3,'Kitchen Sanitation',2),
(7,4,'Cooking Procedures',3),(7,5,'Food Utilization',3),(7,6,'Quantity Meal Preparation',3),
(7,7,'ServSafe Certification Prep',3),(7,8,'Advanced Cooking Techniques',3),
(7,9,'Practical Kitchen Experience',4),(7,10,'Job Readiness and Final Assessment',4),
-- Tanya Williams (8): low-moderate throughout
(8,1,'Knife Skills',3),(8,2,'Food Safety',2),(8,3,'Kitchen Sanitation',2),
(8,4,'Cooking Procedures',3),(8,5,'Food Utilization',3),(8,6,'Quantity Meal Preparation',3),
(8,7,'ServSafe Certification Prep',3),(8,8,'Advanced Cooking Techniques',3),
(8,9,'Practical Kitchen Experience',3),(8,10,'Job Readiness and Final Assessment',4),
-- Marcus Hill (9): weeks 1–5 only, declining
(9,1,'Knife Skills',3),(9,2,'Food Safety',3),(9,3,'Kitchen Sanitation',2),
(9,4,'Cooking Procedures',2),(9,5,'Food Utilization',2),
-- Rosa Flores (10): weeks 1–2 only
(10,1,'Knife Skills',3),(10,2,'Food Safety',2);

-- ─── ATTENDANCE LOGS ──────────────────────────────────────────────────
-- Week 1: Apr 7–11 | Week 2: Apr 14–18 | Week 3: Apr 21–25
-- Week 4: Apr 28–May 2 | Week 5: May 5–9 | Week 6: May 12–16
-- Week 7: May 19–23 | Week 8: May 26–30 | Week 9: Jun 2–6 | Week 10: Jun 9–13
INSERT INTO attendance_logs (participant_id, log_date, week_number, status, absence_reason) VALUES
-- ── Maria Chen (1): near-perfect, 1 late ──────────────────────────────
(1,'2026-04-07',1,'present',NULL),(1,'2026-04-08',1,'present',NULL),(1,'2026-04-09',1,'present',NULL),(1,'2026-04-10',1,'present',NULL),(1,'2026-04-11',1,'present',NULL),
(1,'2026-04-14',2,'present',NULL),(1,'2026-04-15',2,'present',NULL),(1,'2026-04-16',2,'present',NULL),(1,'2026-04-17',2,'present',NULL),(1,'2026-04-18',2,'present',NULL),
(1,'2026-04-21',3,'present',NULL),(1,'2026-04-22',3,'present',NULL),(1,'2026-04-23',3,'present',NULL),(1,'2026-04-24',3,'present',NULL),(1,'2026-04-25',3,'present',NULL),
(1,'2026-04-28',4,'present',NULL),(1,'2026-04-29',4,'present',NULL),(1,'2026-04-30',4,'late','Bus delay'),(1,'2026-05-01',4,'present',NULL),(1,'2026-05-02',4,'present',NULL),
(1,'2026-05-05',5,'present',NULL),(1,'2026-05-06',5,'present',NULL),(1,'2026-05-07',5,'present',NULL),(1,'2026-05-08',5,'present',NULL),(1,'2026-05-09',5,'present',NULL),
(1,'2026-05-12',6,'present',NULL),(1,'2026-05-13',6,'present',NULL),(1,'2026-05-14',6,'present',NULL),(1,'2026-05-15',6,'present',NULL),(1,'2026-05-16',6,'present',NULL),
(1,'2026-05-19',7,'present',NULL),(1,'2026-05-20',7,'present',NULL),(1,'2026-05-21',7,'present',NULL),(1,'2026-05-22',7,'present',NULL),(1,'2026-05-23',7,'present',NULL),
(1,'2026-05-26',8,'present',NULL),(1,'2026-05-27',8,'present',NULL),(1,'2026-05-28',8,'present',NULL),(1,'2026-05-29',8,'present',NULL),(1,'2026-05-30',8,'present',NULL),
(1,'2026-06-02',9,'present',NULL),(1,'2026-06-03',9,'present',NULL),(1,'2026-06-04',9,'present',NULL),(1,'2026-06-05',9,'present',NULL),(1,'2026-06-06',9,'present',NULL),
(1,'2026-06-09',10,'present',NULL),(1,'2026-06-10',10,'present',NULL),(1,'2026-06-11',10,'present',NULL),(1,'2026-06-12',10,'present',NULL),(1,'2026-06-13',10,'present',NULL),
-- ── James Nguyen (2): 1 excused absence ──────────────────────────────
(2,'2026-04-07',1,'present',NULL),(2,'2026-04-08',1,'present',NULL),(2,'2026-04-09',1,'present',NULL),(2,'2026-04-10',1,'present',NULL),(2,'2026-04-11',1,'present',NULL),
(2,'2026-04-14',2,'present',NULL),(2,'2026-04-15',2,'present',NULL),(2,'2026-04-16',2,'present',NULL),(2,'2026-04-17',2,'present',NULL),(2,'2026-04-18',2,'present',NULL),
(2,'2026-04-21',3,'present',NULL),(2,'2026-04-22',3,'present',NULL),(2,'2026-04-23',3,'present',NULL),(2,'2026-04-24',3,'present',NULL),(2,'2026-04-25',3,'present',NULL),
(2,'2026-04-28',4,'present',NULL),(2,'2026-04-29',4,'present',NULL),(2,'2026-04-30',4,'present',NULL),(2,'2026-05-01',4,'present',NULL),(2,'2026-05-02',4,'present',NULL),
(2,'2026-05-05',5,'present',NULL),(2,'2026-05-06',5,'excused','Medical appointment'),(2,'2026-05-07',5,'present',NULL),(2,'2026-05-08',5,'present',NULL),(2,'2026-05-09',5,'present',NULL),
(2,'2026-05-12',6,'present',NULL),(2,'2026-05-13',6,'present',NULL),(2,'2026-05-14',6,'present',NULL),(2,'2026-05-15',6,'present',NULL),(2,'2026-05-16',6,'present',NULL),
(2,'2026-05-19',7,'present',NULL),(2,'2026-05-20',7,'present',NULL),(2,'2026-05-21',7,'present',NULL),(2,'2026-05-22',7,'present',NULL),(2,'2026-05-23',7,'present',NULL),
(2,'2026-05-26',8,'present',NULL),(2,'2026-05-27',8,'present',NULL),(2,'2026-05-28',8,'present',NULL),(2,'2026-05-29',8,'present',NULL),(2,'2026-05-30',8,'present',NULL),
(2,'2026-06-02',9,'present',NULL),(2,'2026-06-03',9,'present',NULL),(2,'2026-06-04',9,'present',NULL),(2,'2026-06-05',9,'present',NULL),(2,'2026-06-06',9,'present',NULL),
(2,'2026-06-09',10,'present',NULL),(2,'2026-06-10',10,'present',NULL),(2,'2026-06-11',10,'present',NULL),(2,'2026-06-12',10,'present',NULL),(2,'2026-06-13',10,'present',NULL),
-- ── Amara Osei (3): perfect attendance ───────────────────────────────
(3,'2026-04-07',1,'present',NULL),(3,'2026-04-08',1,'present',NULL),(3,'2026-04-09',1,'present',NULL),(3,'2026-04-10',1,'present',NULL),(3,'2026-04-11',1,'present',NULL),
(3,'2026-04-14',2,'present',NULL),(3,'2026-04-15',2,'present',NULL),(3,'2026-04-16',2,'present',NULL),(3,'2026-04-17',2,'present',NULL),(3,'2026-04-18',2,'present',NULL),
(3,'2026-04-21',3,'present',NULL),(3,'2026-04-22',3,'present',NULL),(3,'2026-04-23',3,'present',NULL),(3,'2026-04-24',3,'present',NULL),(3,'2026-04-25',3,'present',NULL),
(3,'2026-04-28',4,'present',NULL),(3,'2026-04-29',4,'present',NULL),(3,'2026-04-30',4,'present',NULL),(3,'2026-05-01',4,'present',NULL),(3,'2026-05-02',4,'present',NULL),
(3,'2026-05-05',5,'present',NULL),(3,'2026-05-06',5,'present',NULL),(3,'2026-05-07',5,'present',NULL),(3,'2026-05-08',5,'present',NULL),(3,'2026-05-09',5,'present',NULL),
(3,'2026-05-12',6,'present',NULL),(3,'2026-05-13',6,'present',NULL),(3,'2026-05-14',6,'present',NULL),(3,'2026-05-15',6,'present',NULL),(3,'2026-05-16',6,'present',NULL),
(3,'2026-05-19',7,'present',NULL),(3,'2026-05-20',7,'present',NULL),(3,'2026-05-21',7,'present',NULL),(3,'2026-05-22',7,'present',NULL),(3,'2026-05-23',7,'present',NULL),
(3,'2026-05-26',8,'present',NULL),(3,'2026-05-27',8,'present',NULL),(3,'2026-05-28',8,'present',NULL),(3,'2026-05-29',8,'present',NULL),(3,'2026-05-30',8,'present',NULL),
(3,'2026-06-02',9,'present',NULL),(3,'2026-06-03',9,'present',NULL),(3,'2026-06-04',9,'present',NULL),(3,'2026-06-05',9,'present',NULL),(3,'2026-06-06',9,'present',NULL),
(3,'2026-06-09',10,'present',NULL),(3,'2026-06-10',10,'present',NULL),(3,'2026-06-11',10,'present',NULL),(3,'2026-06-12',10,'present',NULL),(3,'2026-06-13',10,'present',NULL),
-- ── Sofia Reyes (4): 2 absences during childcare crisis wk 3–4 ───────
(4,'2026-04-07',1,'present',NULL),(4,'2026-04-08',1,'present',NULL),(4,'2026-04-09',1,'present',NULL),(4,'2026-04-10',1,'present',NULL),(4,'2026-04-11',1,'present',NULL),
(4,'2026-04-14',2,'present',NULL),(4,'2026-04-15',2,'present',NULL),(4,'2026-04-16',2,'present',NULL),(4,'2026-04-17',2,'present',NULL),(4,'2026-04-18',2,'present',NULL),
(4,'2026-04-21',3,'present',NULL),(4,'2026-04-22',3,'present',NULL),(4,'2026-04-23',3,'absent','Childcare breakdown'),(4,'2026-04-24',3,'present',NULL),(4,'2026-04-25',3,'present',NULL),
(4,'2026-04-28',4,'present',NULL),(4,'2026-04-29',4,'absent','Childcare issue'),(4,'2026-04-30',4,'present',NULL),(4,'2026-05-01',4,'present',NULL),(4,'2026-05-02',4,'present',NULL),
(4,'2026-05-05',5,'present',NULL),(4,'2026-05-06',5,'present',NULL),(4,'2026-05-07',5,'present',NULL),(4,'2026-05-08',5,'present',NULL),(4,'2026-05-09',5,'present',NULL),
(4,'2026-05-12',6,'present',NULL),(4,'2026-05-13',6,'present',NULL),(4,'2026-05-14',6,'present',NULL),(4,'2026-05-15',6,'present',NULL),(4,'2026-05-16',6,'present',NULL),
(4,'2026-05-19',7,'present',NULL),(4,'2026-05-20',7,'present',NULL),(4,'2026-05-21',7,'present',NULL),(4,'2026-05-22',7,'present',NULL),(4,'2026-05-23',7,'present',NULL),
(4,'2026-05-26',8,'present',NULL),(4,'2026-05-27',8,'present',NULL),(4,'2026-05-28',8,'present',NULL),(4,'2026-05-29',8,'present',NULL),(4,'2026-05-30',8,'present',NULL),
(4,'2026-06-02',9,'present',NULL),(4,'2026-06-03',9,'present',NULL),(4,'2026-06-04',9,'present',NULL),(4,'2026-06-05',9,'present',NULL),(4,'2026-06-06',9,'present',NULL),
(4,'2026-06-09',10,'present',NULL),(4,'2026-06-10',10,'present',NULL),(4,'2026-06-11',10,'present',NULL),(4,'2026-06-12',10,'present',NULL),(4,'2026-06-13',10,'present',NULL),
-- ── Derek Johnson (5): 3 absences during housing crisis wk 2–3 ───────
(5,'2026-04-07',1,'present',NULL),(5,'2026-04-08',1,'present',NULL),(5,'2026-04-09',1,'present',NULL),(5,'2026-04-10',1,'present',NULL),(5,'2026-04-11',1,'present',NULL),
(5,'2026-04-14',2,'present',NULL),(5,'2026-04-15',2,'present',NULL),(5,'2026-04-16',2,'absent','Housing search appointment'),(5,'2026-04-17',2,'present',NULL),(5,'2026-04-18',2,'present',NULL),
(5,'2026-04-21',3,'absent','Housing crisis'),(5,'2026-04-22',3,'absent','Housing crisis'),(5,'2026-04-23',3,'present',NULL),(5,'2026-04-24',3,'present',NULL),(5,'2026-04-25',3,'present',NULL),
(5,'2026-04-28',4,'present',NULL),(5,'2026-04-29',4,'present',NULL),(5,'2026-04-30',4,'present',NULL),(5,'2026-05-01',4,'present',NULL),(5,'2026-05-02',4,'present',NULL),
(5,'2026-05-05',5,'present',NULL),(5,'2026-05-06',5,'present',NULL),(5,'2026-05-07',5,'present',NULL),(5,'2026-05-08',5,'present',NULL),(5,'2026-05-09',5,'present',NULL),
(5,'2026-05-12',6,'present',NULL),(5,'2026-05-13',6,'present',NULL),(5,'2026-05-14',6,'present',NULL),(5,'2026-05-15',6,'present',NULL),(5,'2026-05-16',6,'present',NULL),
(5,'2026-05-19',7,'present',NULL),(5,'2026-05-20',7,'present',NULL),(5,'2026-05-21',7,'present',NULL),(5,'2026-05-22',7,'present',NULL),(5,'2026-05-23',7,'present',NULL),
(5,'2026-05-26',8,'present',NULL),(5,'2026-05-27',8,'present',NULL),(5,'2026-05-28',8,'present',NULL),(5,'2026-05-29',8,'present',NULL),(5,'2026-05-30',8,'present',NULL),
(5,'2026-06-02',9,'present',NULL),(5,'2026-06-03',9,'present',NULL),(5,'2026-06-04',9,'present',NULL),(5,'2026-06-05',9,'present',NULL),(5,'2026-06-06',9,'present',NULL),
(5,'2026-06-09',10,'present',NULL),(5,'2026-06-10',10,'present',NULL),(5,'2026-06-11',10,'present',NULL),(5,'2026-06-12',10,'present',NULL),(5,'2026-06-13',10,'present',NULL),
-- ── Linda Yazzie (6): 1 absence during financial spike wk 5 ──────────
(6,'2026-04-07',1,'present',NULL),(6,'2026-04-08',1,'present',NULL),(6,'2026-04-09',1,'present',NULL),(6,'2026-04-10',1,'present',NULL),(6,'2026-04-11',1,'present',NULL),
(6,'2026-04-14',2,'present',NULL),(6,'2026-04-15',2,'present',NULL),(6,'2026-04-16',2,'present',NULL),(6,'2026-04-17',2,'present',NULL),(6,'2026-04-18',2,'present',NULL),
(6,'2026-04-21',3,'present',NULL),(6,'2026-04-22',3,'present',NULL),(6,'2026-04-23',3,'present',NULL),(6,'2026-04-24',3,'present',NULL),(6,'2026-04-25',3,'present',NULL),
(6,'2026-04-28',4,'present',NULL),(6,'2026-04-29',4,'present',NULL),(6,'2026-04-30',4,'present',NULL),(6,'2026-05-01',4,'present',NULL),(6,'2026-05-02',4,'present',NULL),
(6,'2026-05-05',5,'present',NULL),(6,'2026-05-06',5,'absent','Financial emergency'),(6,'2026-05-07',5,'present',NULL),(6,'2026-05-08',5,'present',NULL),(6,'2026-05-09',5,'present',NULL),
(6,'2026-05-12',6,'present',NULL),(6,'2026-05-13',6,'present',NULL),(6,'2026-05-14',6,'present',NULL),(6,'2026-05-15',6,'present',NULL),(6,'2026-05-16',6,'present',NULL),
(6,'2026-05-19',7,'present',NULL),(6,'2026-05-20',7,'present',NULL),(6,'2026-05-21',7,'present',NULL),(6,'2026-05-22',7,'present',NULL),(6,'2026-05-23',7,'present',NULL),
(6,'2026-05-26',8,'present',NULL),(6,'2026-05-27',8,'present',NULL),(6,'2026-05-28',8,'present',NULL),(6,'2026-05-29',8,'present',NULL),(6,'2026-05-30',8,'present',NULL),
(6,'2026-06-02',9,'present',NULL),(6,'2026-06-03',9,'present',NULL),(6,'2026-06-04',9,'present',NULL),(6,'2026-06-05',9,'present',NULL),(6,'2026-06-06',9,'present',NULL),
(6,'2026-06-09',10,'present',NULL),(6,'2026-06-10',10,'present',NULL),(6,'2026-06-11',10,'present',NULL),(6,'2026-06-12',10,'present',NULL),(6,'2026-06-13',10,'present',NULL),
-- ── Carlos Mendez (7): mostly present, recurring late due to bus ──────
(7,'2026-04-07',1,'late','Bus late'),(7,'2026-04-08',1,'present',NULL),(7,'2026-04-09',1,'present',NULL),(7,'2026-04-10',1,'present',NULL),(7,'2026-04-11',1,'present',NULL),
(7,'2026-04-14',2,'present',NULL),(7,'2026-04-15',2,'late','Bus late'),(7,'2026-04-16',2,'present',NULL),(7,'2026-04-17',2,'present',NULL),(7,'2026-04-18',2,'present',NULL),
(7,'2026-04-21',3,'present',NULL),(7,'2026-04-22',3,'present',NULL),(7,'2026-04-23',3,'late','Bus late'),(7,'2026-04-24',3,'present',NULL),(7,'2026-04-25',3,'present',NULL),
(7,'2026-04-28',4,'present',NULL),(7,'2026-04-29',4,'present',NULL),(7,'2026-04-30',4,'present',NULL),(7,'2026-05-01',4,'late','Bus late'),(7,'2026-05-02',4,'present',NULL),
(7,'2026-05-05',5,'present',NULL),(7,'2026-05-06',5,'present',NULL),(7,'2026-05-07',5,'late','Bus late'),(7,'2026-05-08',5,'present',NULL),(7,'2026-05-09',5,'present',NULL),
(7,'2026-05-12',6,'present',NULL),(7,'2026-05-13',6,'present',NULL),(7,'2026-05-14',6,'present',NULL),(7,'2026-05-15',6,'late','Bus late'),(7,'2026-05-16',6,'present',NULL),
(7,'2026-05-19',7,'present',NULL),(7,'2026-05-20',7,'present',NULL),(7,'2026-05-21',7,'present',NULL),(7,'2026-05-22',7,'present',NULL),(7,'2026-05-23',7,'present',NULL),
(7,'2026-05-26',8,'present',NULL),(7,'2026-05-27',8,'present',NULL),(7,'2026-05-28',8,'present',NULL),(7,'2026-05-29',8,'present',NULL),(7,'2026-05-30',8,'present',NULL),
(7,'2026-06-02',9,'present',NULL),(7,'2026-06-03',9,'present',NULL),(7,'2026-06-04',9,'present',NULL),(7,'2026-06-05',9,'present',NULL),(7,'2026-06-06',9,'present',NULL),
(7,'2026-06-09',10,'present',NULL),(7,'2026-06-10',10,'present',NULL),(7,'2026-06-11',10,'present',NULL),(7,'2026-06-12',10,'present',NULL),(7,'2026-06-13',10,'present',NULL),
-- ── Tanya Williams (8): mostly present, 3 absences during worst weeks ─
(8,'2026-04-07',1,'present',NULL),(8,'2026-04-08',1,'present',NULL),(8,'2026-04-09',1,'present',NULL),(8,'2026-04-10',1,'present',NULL),(8,'2026-04-11',1,'present',NULL),
(8,'2026-04-14',2,'present',NULL),(8,'2026-04-15',2,'present',NULL),(8,'2026-04-16',2,'absent','Housing instability'),(8,'2026-04-17',2,'present',NULL),(8,'2026-04-18',2,'present',NULL),
(8,'2026-04-21',3,'present',NULL),(8,'2026-04-22',3,'absent','Housing instability'),(8,'2026-04-23',3,'present',NULL),(8,'2026-04-24',3,'present',NULL),(8,'2026-04-25',3,'present',NULL),
(8,'2026-04-28',4,'present',NULL),(8,'2026-04-29',4,'present',NULL),(8,'2026-04-30',4,'present',NULL),(8,'2026-05-01',4,'present',NULL),(8,'2026-05-02',4,'present',NULL),
(8,'2026-05-05',5,'present',NULL),(8,'2026-05-06',5,'present',NULL),(8,'2026-05-07',5,'present',NULL),(8,'2026-05-08',5,'absent','Housing instability'),(8,'2026-05-09',5,'present',NULL),
(8,'2026-05-12',6,'present',NULL),(8,'2026-05-13',6,'present',NULL),(8,'2026-05-14',6,'present',NULL),(8,'2026-05-15',6,'present',NULL),(8,'2026-05-16',6,'present',NULL),
(8,'2026-05-19',7,'present',NULL),(8,'2026-05-20',7,'present',NULL),(8,'2026-05-21',7,'present',NULL),(8,'2026-05-22',7,'present',NULL),(8,'2026-05-23',7,'present',NULL),
(8,'2026-05-26',8,'present',NULL),(8,'2026-05-27',8,'present',NULL),(8,'2026-05-28',8,'present',NULL),(8,'2026-05-29',8,'present',NULL),(8,'2026-05-30',8,'present',NULL),
(8,'2026-06-02',9,'present',NULL),(8,'2026-06-03',9,'present',NULL),(8,'2026-06-04',9,'present',NULL),(8,'2026-06-05',9,'present',NULL),(8,'2026-06-06',9,'present',NULL),
(8,'2026-06-09',10,'present',NULL),(8,'2026-06-10',10,'present',NULL),(8,'2026-06-11',10,'present',NULL),(8,'2026-06-12',10,'present',NULL),(8,'2026-06-13',10,'present',NULL),
-- ── Marcus Hill (9): deteriorating wk 3–5, absent all of wk 5, dropped
(9,'2026-04-07',1,'present',NULL),(9,'2026-04-08',1,'present',NULL),(9,'2026-04-09',1,'present',NULL),(9,'2026-04-10',1,'present',NULL),(9,'2026-04-11',1,'present',NULL),
(9,'2026-04-14',2,'present',NULL),(9,'2026-04-15',2,'present',NULL),(9,'2026-04-16',2,'late','Unspecified'),(9,'2026-04-17',2,'present',NULL),(9,'2026-04-18',2,'present',NULL),
(9,'2026-04-21',3,'present',NULL),(9,'2026-04-22',3,'absent','No contact'),(9,'2026-04-23',3,'present',NULL),(9,'2026-04-24',3,'absent','No contact'),(9,'2026-04-25',3,'present',NULL),
(9,'2026-04-28',4,'absent','No contact'),(9,'2026-04-29',4,'absent','No contact'),(9,'2026-04-30',4,'present',NULL),(9,'2026-05-01',4,'absent','No contact'),(9,'2026-05-02',4,'absent','No contact'),
(9,'2026-05-05',5,'absent','No contact'),(9,'2026-05-06',5,'absent','No contact'),(9,'2026-05-07',5,'absent','No contact'),(9,'2026-05-08',5,'absent','No contact'),(9,'2026-05-09',5,'absent','No contact'),
-- ── Rosa Flores (10): wk 1 present, absences wk 2, absent all wk 3 ───
(10,'2026-04-07',1,'present',NULL),(10,'2026-04-08',1,'present',NULL),(10,'2026-04-09',1,'present',NULL),(10,'2026-04-10',1,'present',NULL),(10,'2026-04-11',1,'present',NULL),
(10,'2026-04-14',2,'late','Child sick'),(10,'2026-04-15',2,'absent','Child sick'),(10,'2026-04-16',2,'present',NULL),(10,'2026-04-17',2,'absent','Childcare breakdown'),(10,'2026-04-18',2,'present',NULL),
(10,'2026-04-21',3,'absent','No contact'),(10,'2026-04-22',3,'absent','No contact'),(10,'2026-04-23',3,'absent','No contact'),(10,'2026-04-24',3,'absent','No contact'),(10,'2026-04-25',3,'absent','No contact');

-- ─── DASHBOARD ACTIVITY LOGS (end-of-week summary per participant) ─────
INSERT INTO dashboard_activity_logs
  (participant_id, log_date, week_number,
   login_count, coursework_completed, quests_completed, current_streak_days, total_points)
VALUES
-- Maria Chen (1): high, consistent engagement
(1,'2026-04-11',1,5,4,2,5,120),(1,'2026-04-18',2,5,4,2,10,240),
(1,'2026-04-25',3,5,3,2,15,350),(1,'2026-05-02',4,5,4,2,20,470),
(1,'2026-05-09',5,5,4,3,25,610),(1,'2026-05-16',6,5,4,2,30,730),
(1,'2026-05-23',7,5,5,3,35,880),(1,'2026-05-30',8,5,4,2,40,1000),
(1,'2026-06-06',9,5,5,3,45,1150),(1,'2026-06-13',10,5,5,3,50,1300),
-- James Nguyen (2): steady
(2,'2026-04-11',1,4,3,1,5,90),(2,'2026-04-18',2,5,3,2,10,210),
(2,'2026-04-25',3,5,3,1,15,310),(2,'2026-05-02',4,5,3,2,20,430),
(2,'2026-05-09',5,4,3,1,24,530),(2,'2026-05-16',6,5,3,2,29,650),
(2,'2026-05-23',7,5,4,2,34,790),(2,'2026-05-30',8,5,3,2,39,910),
(2,'2026-06-06',9,5,4,2,44,1050),(2,'2026-06-13',10,5,4,2,49,1190),
-- Amara Osei (3): highest engagement
(3,'2026-04-11',1,5,5,3,5,150),(3,'2026-04-18',2,5,5,3,10,300),
(3,'2026-04-25',3,5,5,3,15,450),(3,'2026-05-02',4,5,5,3,20,600),
(3,'2026-05-09',5,5,5,3,25,750),(3,'2026-05-16',6,5,5,3,30,900),
(3,'2026-05-23',7,5,5,3,35,1050),(3,'2026-05-30',8,5,5,3,40,1200),
(3,'2026-06-06',9,5,5,3,45,1350),(3,'2026-06-13',10,5,5,3,50,1500),
-- Sofia Reyes (4): dip wk 3–4, recovers wk 5+
(4,'2026-04-11',1,5,4,2,5,120),(4,'2026-04-18',2,5,3,2,10,230),
(4,'2026-04-25',3,3,2,1,12,280),(4,'2026-05-02',4,3,2,1,14,330),
(4,'2026-05-09',5,5,4,2,19,450),(4,'2026-05-16',6,5,4,2,24,570),
(4,'2026-05-23',7,5,4,2,29,690),(4,'2026-05-30',8,5,4,2,34,810),
(4,'2026-06-06',9,5,5,3,39,960),(4,'2026-06-13',10,5,5,3,44,1110),
-- Derek Johnson (5): dip wk 2–3, recovers wk 4+
(5,'2026-04-11',1,4,3,1,5,90),(5,'2026-04-18',2,3,2,1,7,140),
(5,'2026-04-25',3,2,1,0,8,160),(5,'2026-05-02',4,4,3,2,13,290),
(5,'2026-05-09',5,5,3,2,18,410),(5,'2026-05-16',6,5,3,2,23,530),
(5,'2026-05-23',7,5,4,2,28,670),(5,'2026-05-30',8,5,4,2,33,810),
(5,'2026-06-06',9,5,4,2,38,930),(5,'2026-06-13',10,5,5,2,43,1060),
-- Linda Yazzie (6): dip wk 5, recovers wk 6+
(6,'2026-04-11',1,5,3,2,5,110),(6,'2026-04-18',2,5,3,2,10,230),
(6,'2026-04-25',3,5,3,2,15,350),(6,'2026-05-02',4,5,3,2,20,470),
(6,'2026-05-09',5,2,1,0,21,490),(6,'2026-05-16',6,5,4,2,26,620),
(6,'2026-05-23',7,5,3,2,31,740),(6,'2026-05-30',8,5,3,2,36,860),
(6,'2026-06-06',9,5,4,2,41,990),(6,'2026-06-13',10,5,4,2,46,1120),
-- Carlos Mendez (7): lower engagement due to transport challenges
(7,'2026-04-11',1,4,2,1,4,70),(7,'2026-04-18',2,4,2,1,8,140),
(7,'2026-04-25',3,4,2,1,12,210),(7,'2026-05-02',4,4,3,1,16,300),
(7,'2026-05-09',5,4,2,1,20,370),(7,'2026-05-16',6,4,3,1,24,460),
(7,'2026-05-23',7,4,2,1,28,530),(7,'2026-05-30',8,4,3,1,32,620),
(7,'2026-06-06',9,4,3,1,36,710),(7,'2026-06-13',10,5,3,2,41,830),
-- Tanya Williams (8): low but persistent engagement
(8,'2026-04-11',1,3,2,1,4,70),(8,'2026-04-18',2,3,2,1,7,130),
(8,'2026-04-25',3,3,2,0,9,170),(8,'2026-05-02',4,3,2,1,12,240),
(8,'2026-05-09',5,3,2,0,14,280),(8,'2026-05-16',6,4,2,1,18,360),
(8,'2026-05-23',7,4,2,1,22,440),(8,'2026-05-30',8,4,3,1,26,540),
(8,'2026-06-06',9,4,3,1,30,630),(8,'2026-06-13',10,4,3,1,34,720),
-- Marcus Hill (9): declining, wk 1–5 only
(9,'2026-04-11',1,4,3,1,5,100),(9,'2026-04-18',2,4,2,1,9,180),
(9,'2026-04-25',3,3,2,0,10,220),(9,'2026-05-02',4,1,1,0,10,240),
(9,'2026-05-09',5,0,0,0,0,240),
-- Rosa Flores (10): wk 1–2 only
(10,'2026-04-11',1,4,3,1,5,100),(10,'2026-04-18',2,2,1,0,6,130);

-- ─── RISK SCORES ──────────────────────────────────────────────────────
-- Constraint: <0.40=low | 0.40–0.69=medium | >=0.70=high
INSERT INTO risk_scores
  (participant_id, week_number, risk_score, risk_tier, top_features, model_version)
VALUES
-- Maria Chen (1): low throughout
(1,1,0.08,'low','{"financial_stress":0.04,"housing_barrier":0.04}','v1'),
(1,2,0.07,'low','{"financial_stress":0.04,"transport_barrier":0.03}','v1'),
(1,3,0.09,'low','{"financial_stress":0.05,"transport_barrier":0.04}','v1'),
(1,4,0.08,'low','{"financial_stress":0.04,"feeling_overwhelmed":0.04}','v1'),
(1,5,0.08,'low','{"financial_stress":0.05,"housing_barrier":0.03}','v1'),
(1,6,0.07,'low','{"financial_stress":0.04,"transport_barrier":0.03}','v1'),
(1,7,0.06,'low','{"financial_stress":0.03,"housing_barrier":0.03}','v1'),
(1,8,0.06,'low','{"financial_stress":0.03,"transport_barrier":0.03}','v1'),
(1,9,0.05,'low','{"financial_stress":0.03,"housing_barrier":0.02}','v1'),
(1,10,0.04,'low','{"financial_stress":0.02,"transport_barrier":0.02}','v1'),
-- James Nguyen (2): low throughout
(2,1,0.12,'low','{"housing_barrier":0.07,"feeling_overwhelmed":0.05}','v1'),
(2,2,0.11,'low','{"housing_barrier":0.06,"feeling_overwhelmed":0.05}','v1'),
(2,3,0.11,'low','{"housing_barrier":0.06,"financial_stress":0.05}','v1'),
(2,4,0.10,'low','{"housing_barrier":0.06,"financial_stress":0.04}','v1'),
(2,5,0.10,'low','{"housing_barrier":0.05,"feeling_overwhelmed":0.05}','v1'),
(2,6,0.09,'low','{"housing_barrier":0.05,"financial_stress":0.04}','v1'),
(2,7,0.08,'low','{"housing_barrier":0.04,"financial_stress":0.04}','v1'),
(2,8,0.07,'low','{"housing_barrier":0.04,"financial_stress":0.03}','v1'),
(2,9,0.06,'low','{"housing_barrier":0.03,"financial_stress":0.03}','v1'),
(2,10,0.05,'low','{"housing_barrier":0.03,"financial_stress":0.02}','v1'),
-- Amara Osei (3): very low throughout
(3,1,0.05,'low','{"transport_barrier":0.03,"financial_stress":0.02}','v1'),
(3,2,0.05,'low','{"transport_barrier":0.03,"financial_stress":0.02}','v1'),
(3,3,0.04,'low','{"transport_barrier":0.02,"financial_stress":0.02}','v1'),
(3,4,0.04,'low','{"transport_barrier":0.02,"financial_stress":0.02}','v1'),
(3,5,0.04,'low','{"transport_barrier":0.02,"financial_stress":0.02}','v1'),
(3,6,0.03,'low','{"transport_barrier":0.02,"financial_stress":0.01}','v1'),
(3,7,0.03,'low','{"transport_barrier":0.02,"financial_stress":0.01}','v1'),
(3,8,0.03,'low','{"transport_barrier":0.01,"financial_stress":0.02}','v1'),
(3,9,0.02,'low','{"transport_barrier":0.01,"financial_stress":0.01}','v1'),
(3,10,0.02,'low','{"transport_barrier":0.01,"financial_stress":0.01}','v1'),
-- Sofia Reyes (4): spikes wk 3–4, recovered wk 5+
(4,1,0.22,'low', '{"childcare_barrier":0.12,"financial_stress":0.10}','v1'),
(4,2,0.33,'low', '{"childcare_barrier":0.18,"feeling_overwhelmed":0.15}','v1'),
(4,3,0.74,'high','{"childcare_barrier":0.38,"motivation_drop":0.22,"feeling_overwhelmed":0.14}','v1'),
(4,4,0.61,'medium','{"childcare_barrier":0.28,"financial_stress":0.20,"motivation_drop":0.13}','v1'),
(4,5,0.28,'low', '{"childcare_barrier":0.15,"financial_stress":0.13}','v1'),
(4,6,0.22,'low', '{"childcare_barrier":0.12,"financial_stress":0.10}','v1'),
(4,7,0.18,'low', '{"childcare_barrier":0.10,"financial_stress":0.08}','v1'),
(4,8,0.15,'low', '{"childcare_barrier":0.08,"financial_stress":0.07}','v1'),
(4,9,0.11,'low', '{"financial_stress":0.06,"childcare_barrier":0.05}','v1'),
(4,10,0.08,'low','{"financial_stress":0.04,"childcare_barrier":0.04}','v1'),
-- Derek Johnson (5): spikes wk 2–3, recovered wk 4+
(5,1,0.28,'low',   '{"housing_barrier":0.18,"feeling_overwhelmed":0.10}','v1'),
(5,2,0.48,'medium','{"housing_barrier":0.28,"financial_stress":0.12,"motivation_drop":0.08}','v1'),
(5,3,0.81,'high',  '{"housing_barrier":0.42,"motivation_drop":0.25,"attendance":0.14}','v1'),
(5,4,0.35,'low',   '{"housing_barrier":0.20,"financial_stress":0.15}','v1'),
(5,5,0.22,'low',   '{"housing_barrier":0.12,"financial_stress":0.10}','v1'),
(5,6,0.18,'low',   '{"housing_barrier":0.10,"financial_stress":0.08}','v1'),
(5,7,0.15,'low',   '{"housing_barrier":0.08,"financial_stress":0.07}','v1'),
(5,8,0.12,'low',   '{"housing_barrier":0.07,"financial_stress":0.05}','v1'),
(5,9,0.09,'low',   '{"housing_barrier":0.05,"financial_stress":0.04}','v1'),
(5,10,0.07,'low',  '{"housing_barrier":0.04,"financial_stress":0.03}','v1'),
-- Linda Yazzie (6): financial spike wk 5, recovered wk 6+
(6,1,0.18,'low',   '{"financial_stress":0.10,"transport_barrier":0.08}','v1'),
(6,2,0.19,'low',   '{"financial_stress":0.10,"transport_barrier":0.09}','v1'),
(6,3,0.20,'low',   '{"financial_stress":0.11,"transport_barrier":0.09}','v1'),
(6,4,0.21,'low',   '{"financial_stress":0.12,"transport_barrier":0.09}','v1'),
(6,5,0.68,'medium','{"financial_stress_spike":0.38,"motivation_drop":0.20,"feeling_overwhelmed":0.10}','v1'),
(6,6,0.28,'low',   '{"financial_stress":0.15,"transport_barrier":0.13}','v1'),
(6,7,0.22,'low',   '{"financial_stress":0.12,"transport_barrier":0.10}','v1'),
(6,8,0.19,'low',   '{"financial_stress":0.10,"transport_barrier":0.09}','v1'),
(6,9,0.15,'low',   '{"financial_stress":0.08,"transport_barrier":0.07}','v1'),
(6,10,0.11,'low',  '{"financial_stress":0.06,"transport_barrier":0.05}','v1'),
-- Carlos Mendez (7): persistently medium, never resolved
(7,1,0.58,'medium','{"transport_barrier":0.28,"financial_stress":0.18,"housing_barrier":0.12}','v1'),
(7,2,0.61,'medium','{"transport_barrier":0.30,"financial_stress":0.18,"feeling_overwhelmed":0.13}','v1'),
(7,3,0.64,'medium','{"transport_barrier":0.30,"housing_barrier":0.20,"motivation_drop":0.14}','v1'),
(7,4,0.60,'medium','{"transport_barrier":0.28,"financial_stress":0.18,"housing_barrier":0.14}','v1'),
(7,5,0.63,'medium','{"transport_barrier":0.30,"financial_stress":0.20,"housing_barrier":0.13}','v1'),
(7,6,0.58,'medium','{"transport_barrier":0.28,"financial_stress":0.16,"housing_barrier":0.14}','v1'),
(7,7,0.55,'medium','{"transport_barrier":0.26,"financial_stress":0.16,"housing_barrier":0.13}','v1'),
(7,8,0.52,'medium','{"transport_barrier":0.25,"financial_stress":0.15,"housing_barrier":0.12}','v1'),
(7,9,0.48,'medium','{"transport_barrier":0.23,"financial_stress":0.14,"housing_barrier":0.11}','v1'),
(7,10,0.42,'medium','{"transport_barrier":0.20,"financial_stress":0.12,"housing_barrier":0.10}','v1'),
-- Tanya Williams (8): persistently high, gradual improvement
(8,1,0.65,'medium','{"housing_barrier":0.30,"feeling_overwhelmed":0.20,"financial_stress":0.15}','v1'),
(8,2,0.72,'high',  '{"housing_barrier":0.35,"feeling_overwhelmed":0.22,"financial_stress":0.15}','v1'),
(8,3,0.75,'high',  '{"housing_barrier":0.35,"motivation_drop":0.25,"feeling_overwhelmed":0.15}','v1'),
(8,4,0.73,'high',  '{"housing_barrier":0.33,"feeling_overwhelmed":0.22,"financial_stress":0.18}','v1'),
(8,5,0.74,'high',  '{"housing_barrier":0.35,"feeling_overwhelmed":0.22,"financial_stress":0.17}','v1'),
(8,6,0.68,'medium','{"housing_barrier":0.32,"feeling_overwhelmed":0.20,"financial_stress":0.16}','v1'),
(8,7,0.65,'medium','{"housing_barrier":0.30,"feeling_overwhelmed":0.20,"financial_stress":0.15}','v1'),
(8,8,0.62,'medium','{"housing_barrier":0.28,"feeling_overwhelmed":0.18,"financial_stress":0.16}','v1'),
(8,9,0.58,'medium','{"housing_barrier":0.25,"feeling_overwhelmed":0.18,"financial_stress":0.15}','v1'),
(8,10,0.52,'medium','{"housing_barrier":0.22,"feeling_overwhelmed":0.16,"financial_stress":0.14}','v1'),
-- Marcus Hill (9): escalating, wk 1–5 only
(9,1,0.32,'low',   '{"housing_barrier":0.18,"transport_barrier":0.14}','v1'),
(9,2,0.48,'medium','{"transport_barrier":0.22,"housing_barrier":0.16,"feeling_overwhelmed":0.10}','v1'),
(9,3,0.65,'medium','{"transport_barrier":0.25,"attendance":0.22,"feeling_overwhelmed":0.18}','v1'),
(9,4,0.85,'high',  '{"missing_reminders":0.40,"attendance":0.28,"transport_barrier":0.17}','v1'),
(9,5,0.96,'high',  '{"missing_reminders":0.45,"attendance":0.35,"transport_barrier":0.16}','v1'),
-- Rosa Flores (10): rapid escalation, wk 1–3 only
(10,1,0.42,'medium','{"childcare_barrier":0.22,"transport_barrier":0.20}','v1'),
(10,2,0.76,'high',  '{"childcare_barrier":0.35,"motivation_drop":0.25,"transport_barrier":0.16}','v1'),
(10,3,0.91,'high',  '{"missing_reminders":0.42,"childcare_barrier":0.30,"attendance":0.19}','v1');

-- ─── RISK EVENTS ──────────────────────────────────────────────────────
INSERT INTO risk_events
  (participant_id, week_number, trigger_type, trigger_value, resolved, resolved_at)
VALUES
-- Sofia Reyes (4): childcare crisis wk 3
(4,3,'childcare_load_change','Childcare barrier jumped from 3 to 5',            TRUE,'2026-05-09 09:00:00+00'),
(4,3,'motivation_drop',      'Motivation score 2 — below 3/5 threshold',        TRUE,'2026-05-09 09:00:00+00'),
-- Derek Johnson (5): housing crisis wk 2–3
(5,2,'housing_instability',  'Housing barrier score 4 — second consecutive week rising',FALSE,NULL),
(5,3,'housing_instability',  'Housing barrier score 5 — critical level',         TRUE,'2026-04-28 09:00:00+00'),
(5,3,'motivation_drop',      'Motivation score 2 — below 3/5 threshold',        TRUE,'2026-04-28 09:00:00+00'),
-- Linda Yazzie (6): financial spike wk 5
(6,5,'financial_stress_spike','Financial stress jumped from 3 to 5 week-on-week',TRUE,'2026-05-16 09:00:00+00'),
(6,5,'motivation_drop',      'Motivation score 2 — below 3/5 threshold',        TRUE,'2026-05-16 09:00:00+00'),
-- Carlos Mendez (7): persistent transport barrier
(7,1,'transport_barrier',    'Transport barrier score 5 — no reliable transport at baseline',FALSE,NULL),
(7,3,'transport_barrier',    'Transport barrier score 5 — third consecutive week',FALSE,NULL),
(7,5,'transport_barrier',    'Transport barrier score 5 — fifth consecutive week',FALSE,NULL),
-- Tanya Williams (8): persistent housing instability
(8,2,'housing_instability',  'Housing barrier score 5 — second consecutive week',FALSE,NULL),
(8,3,'motivation_drop',      'Motivation score 2 — below 3/5 threshold',        TRUE,'2026-04-28 09:00:00+00'),
(8,5,'housing_instability',  'Housing barrier score 5 — recurring pattern',      FALSE,NULL),
-- Marcus Hill (9): missing reminders + attendance collapse
(9,4,'missing_reminders',    'No SMS reply — first nudge unanswered',            FALSE,NULL),
(9,5,'missing_reminders',    'No SMS reply — second consecutive week unanswered',FALSE,NULL),
-- Rosa Flores (10): childcare crisis + disappearance
(10,2,'childcare_load_change','Childcare barrier jumped from 4 to 5',            FALSE,NULL),
(10,2,'motivation_drop',     'Motivation score 2 — below 3/5 threshold',        FALSE,NULL),
(10,3,'missing_reminders',   'No SMS reply — no contact for full week',          FALSE,NULL);

-- ─── INTERVENTIONS ────────────────────────────────────────────────────
-- risk_event_id sequence (in INSERT order above):
--  1=Sofia childcare  2=Sofia motivation
--  3=Derek housing wk2  4=Derek housing wk3  5=Derek motivation
--  6=Linda financial  7=Linda motivation
--  8=Carlos transport wk1  9=Carlos transport wk3  10=Carlos transport wk5
--  11=Tanya housing wk2  12=Tanya motivation  13=Tanya housing wk5
--  14=Marcus missing wk4  15=Marcus missing wk5
--  16=Rosa childcare  17=Rosa motivation  18=Rosa missing
INSERT INTO interventions
  (participant_id, risk_event_id, coordinator_id, intervention_type,
   resource_partner, resource_url, resource_maps_link,
   outcome, outcome_notes, closed_at)
VALUES
-- Sofia: DES childcare referral + motivational SMS → both resolved
(4,1,1,'resource_card',
 'Arizona DES Child Care Subsidy','https://des.az.gov/services/child-and-family/childcare',NULL,
 'resolved','Referred to DES childcare subsidy. Sofia confirmed placement for both children by week 5.','2026-05-09 10:00:00+00'),
(4,2,1,'sms_nudge',NULL,NULL,NULL,
 'resolved','Personalised SMS referencing stated goal: raising her children to see her succeed. Motivation recovered to 4 by week 5.','2026-05-09 10:00:00+00'),
-- Derek: Primavera housing referral + phone call + motivational SMS → all resolved
(5,3,1,'resource_card',
 'Primavera Foundation','https://www.primavera.org','https://maps.google.com/?q=Primavera+Foundation+Tucson',
 'resolved','Referred to Primavera Foundation transitional housing. Derek secured stable housing by week 4.','2026-04-28 10:00:00+00'),
(5,4,1,'phone_call',NULL,NULL,NULL,
 'resolved','Called Derek to check in. Confirmed housing situation improving with Primavera support.','2026-04-28 10:00:00+00'),
(5,5,1,'sms_nudge',NULL,NULL,NULL,
 'resolved','Motivational SMS referencing his stated goal. Derek responded positively.','2026-04-28 10:00:00+00'),
-- Linda: two motivational SMS nudges → both resolved
(6,6,1,'sms_nudge',NULL,NULL,NULL,
 'resolved','Sent SMS: "You are ahead of 68% of past participants at this point." Motivation recovered to 4 by week 6.','2026-05-16 10:00:00+00'),
(6,7,1,'sms_nudge',NULL,NULL,NULL,
 'resolved','Personalised SMS referencing her goal of financial independence. Effective.','2026-05-16 10:00:00+00'),
-- Carlos: three Sun Tran resource cards, escalated to supervisor meeting (unresolved)
(7,8,1,'resource_card',
 'Sun Tran','https://suntran.com/fares/','https://maps.google.com/?q=Sun+Tran+Tucson',
 'pending','Sun Tran pass and route info provided. Carlos continues to experience transport delays.',NULL),
(7,9,1,'resource_card',
 'Sun Tran','https://suntran.com/fares/','https://maps.google.com/?q=Sun+Tran+Tucson',
 'pending','Second resource card issued. Exploring carpool options with other participants.',NULL),
(7,10,2,'in_person_meeting',NULL,NULL,NULL,
 'pending','Supervisor met with Carlos to discuss long-term transport plan. Exploring bus pass subsidy grant.',NULL),
-- Tanya: Primavera referral (no response) + SMS (resolved) + supervisor call (pending)
(8,11,1,'resource_card',
 'Primavera Foundation','https://www.primavera.org','https://maps.google.com/?q=Primavera+Foundation+Tucson',
 'no_response','Referred to Primavera. Tanya acknowledged referral but has not followed up.','2026-04-28 10:00:00+00'),
(8,12,1,'sms_nudge',NULL,NULL,NULL,
 'resolved','Personalised SMS referencing stated goal. Motivation recovered to 3 by week 4.','2026-04-28 10:00:00+00'),
(8,13,2,'phone_call',NULL,NULL,NULL,
 'pending','Supervisor called Tanya re: recurring housing instability. Exploring further referral options.',NULL),
-- Marcus: SMS nudge (no response) → phone call (no response) → supervisor visit (no response) → dropped
(9,14,1,'sms_nudge',NULL,NULL,NULL,
 'no_response','Check-in SMS sent. No reply received.','2026-05-09 10:00:00+00'),
(9,15,1,'phone_call',NULL,NULL,NULL,
 'no_response','Called twice. No answer. Coordinator flagged critical dropout risk.','2026-05-14 10:00:00+00'),
(9,15,2,'in_person_meeting',NULL,NULL,NULL,
 'no_response','Supervisor visited program site. Marcus did not appear. Withdrawal processed.','2026-05-14 14:00:00+00'),
-- Rosa: resource card (no response) + SMS nudge (no response) + phone call (no response) → dropped
(10,16,1,'resource_card',
 'Arizona DES Child Care Subsidy','https://des.az.gov/services/child-and-family/childcare',NULL,
 'no_response','DES childcare resource card sent via SMS. Rosa did not respond.','2026-04-30 10:00:00+00'),
(10,17,1,'sms_nudge',NULL,NULL,NULL,
 'no_response','Motivational SMS sent referencing her goal. No reply received.','2026-04-30 10:00:00+00'),
(10,18,1,'phone_call',NULL,NULL,NULL,
 'no_response','Called twice, no answer. Withdrawal processed after no contact for full week 3.','2026-04-30 10:00:00+00');
