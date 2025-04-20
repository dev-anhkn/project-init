-- 1. Tạo các roles chung
CREATE ROLE rl_read;
CREATE ROLE rl_readwrite;

-- 2. Tạo user quản trị database `u_project`
CREATE USER u_project WITH PASSWORD 'u_project';
-- 3. Tạo user thao tác schema `u_account`
CREATE USER u_account WITH PASSWORD 'u_account';

-- 4. Tạo database `db_project` với OWNER là `u_project`
CREATE DATABASE db_project OWNER u_project;

-- 5. Chỉ cho phép role rl_read và rl_readwrite, và user u_account kết nối database
GRANT CONNECT ON DATABASE db_project TO rl_read, rl_readwrite, u_account;

-- 6. Gán quyền đọc-ghi cao nhất cho `u_account`
GRANT rl_readwrite TO u_account;

-- Chuyển sang database `db_project` dưới quyền `u_project`
\c db_project u_project

-- 7. Tạo schema `sch_account` do `u_project` quản lý
CREATE SCHEMA sch_account AUTHORIZATION u_project;

-- 8. Cấp quyền sử dụng schema cho roles và user u_account
GRANT USAGE ON SCHEMA sch_account TO rl_read;
GRANT USAGE, CREATE ON SCHEMA sch_account TO rl_readwrite;

-- Riêng user u_account chỉ thao tác được trong schema sch_account
GRANT USAGE ON SCHEMA sch_account TO u_account;

-- 9. Cấp quyền truy cập tables cho roles
GRANT SELECT ON ALL TABLES IN SCHEMA sch_account TO rl_read;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA sch_account TO rl_readwrite;

-- Cấp quyền mặc định cho tables tương lai
ALTER DEFAULT PRIVILEGES FOR ROLE u_project IN SCHEMA sch_account
    GRANT SELECT ON TABLES TO rl_read;

ALTER DEFAULT PRIVILEGES FOR ROLE u_project IN SCHEMA sch_account
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO rl_readwrite;

-- 10. Đảm bảo user u_account thừa hưởng quyền từ role rl_readwrite
-- (đã thực hiện ở trên: GRANT rl_readwrite TO u_account)

-- 11. Ngăn user u_account tạo schema khác hoặc truy cập ngoài sch_account (Optional)
REVOKE CREATE ON DATABASE db_project FROM u_account;
REVOKE ALL ON SCHEMA public FROM u_account;

-- Chỉ định tìm kiếm schema mặc định cho u_account
\c db_project postgres
ALTER ROLE u_account SET search_path = sch_account;

\c db_project u_account

-- Tạo bảng `account` (Lưu thông tin đăng nhập)
CREATE TABLE sch_account.account
(
    account_code   VARCHAR(50) PRIMARY KEY,
    password_hash  TEXT        NOT NULL,
    account_status VARCHAR(10) NOT NULL DEFAULT 'ACTIVE',
    created_at     TIMESTAMP            DEFAULT now(),
    updated_at     TIMESTAMP            DEFAULT now()
);

-- Tạo bảng `account_info` (Lưu thông tin cá nhân)
CREATE TABLE sch_account.account_info
(
    account_code    VARCHAR(50) PRIMARY KEY,
    account_name    VARCHAR(100),
    account_email   VARCHAR(100) UNIQUE NOT NULL,
    account_mobile  VARCHAR(20),
    account_address TEXT,
    created_at      TIMESTAMP DEFAULT now(),
    updated_at      TIMESTAMP DEFAULT now(),
    CONSTRAINT fk_account_info FOREIGN KEY (account_code) REFERENCES sch_account.account (account_code) ON DELETE CASCADE
);

-- Tạo bảng `role` (Danh sách vai trò)
CREATE TABLE sch_account.role
(
    id          SERIAL PRIMARY KEY,
    code        VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    created_at  TIMESTAMP DEFAULT now()
);

-- Tạo bảng `account_role` (Liên kết tài khoản với vai trò)
CREATE TABLE sch_account.account_role
(
    account_code VARCHAR(50) NOT NULL,
    role_id      INT         NOT NULL,
    CONSTRAINT fk_account_role FOREIGN KEY (account_code) REFERENCES sch_account.account (account_code) ON DELETE CASCADE,
    CONSTRAINT fk_role FOREIGN KEY (role_id) REFERENCES sch_account.role (id) ON DELETE CASCADE,
    PRIMARY KEY (account_code, role_id)
);

-- Thêm dữ liệu vào bảng `role`
INSERT INTO sch_account.role (code, description)
VALUES ('ROLE_ADMIN', 'ADMIN'),
       ('ROLE_USER', 'USER'),
       ('ROLE_EDITOR', 'EDITER')
ON CONFLICT (code) DO NOTHING;

-- Thêm dữ liệu vào bảng `account`
INSERT INTO sch_account.account (account_code, password_hash, account_status)
VALUES ('admin', '$2a$10$rq5q2yaDa9p92EErrvMObeMPWwCkaBYSXhf053CLKj0WjiqeWxr0i', 'ACTIVE')
ON CONFLICT (account_code) DO NOTHING;

-- Thêm dữ liệu vào bảng `account_info`
INSERT INTO sch_account.account_info (account_code, account_name, account_email, account_mobile, account_address)
VALUES ('admin', 'Admin User', 'admin@example.com', '0123456789', '123 Admin Street')
ON CONFLICT (account_code) DO NOTHING;

-- Thêm dữ liệu vào bảng `account_role` (Gán vai trò cho tài khoản)
INSERT INTO sch_account.account_role (account_code, role_id)
VALUES ('admin', (SELECT id FROM sch_account.role WHERE code = 'ROLE_ADMIN'))
ON CONFLICT (account_code, role_id) DO NOTHING;