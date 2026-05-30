-- ============================================================================
-- DATABASE: pharmacy_db | SCHEMA: pharmacy
-- ============================================================================

create schema if not exists pharmacy;

-- ============================================================================
-- PART 1: RE-RUNNABLE HEADER (Drop tables in dependency order)
-- ============================================================================

drop table if exists pharmacy.sale_items     cascade;
drop table if exists pharmacy.sales          cascade;
drop table if exists pharmacy.batches        cascade;
drop table if exists pharmacy.prescriptions  cascade;
drop table if exists pharmacy.medicines      cascade;
drop table if exists pharmacy.suppliers      cascade;
drop table if exists pharmacy.doctors        cascade;
drop table if exists pharmacy.clients        cascade;

-- ============================================================================
-- PART 2: CREATE TABLES
-- ============================================================================

create table if not exists pharmacy.clients (
    client_id   serial        primary key,
    full_name   varchar(100)  not null,
    email       varchar(120)  not null,
    created_at  timestamp     default now()
);

create table if not exists pharmacy.doctors (
    doctor_id       serial       primary key,
    full_name       varchar(100) not null,
    license_number  varchar(50)  not null,
    specialization  varchar(50)  default 'General'
);

create table if not exists pharmacy.suppliers (
    supplier_id       serial        primary key,
    company_name      varchar(100)  not null,
    email             varchar(120)  unique not null,
    phone             varchar(30)   not null  
);

create table if not exists pharmacy.medicines (
    medicine_id              serial         primary key,
    medicine_name            varchar(100)   not null,
    active_ingredient        varchar(100)   not null,
    base_price               numeric(10,2)  not null,
    price_with_vat           numeric(10,2)  generated always as (base_price * 1.12) stored,
    is_prescription_required boolean
);


create table if not exists pharmacy.prescriptions (
    prescription_id  serial  primary key,
    doctor_id        int     not null references pharmacy.doctors(doctor_id) on delete restrict,
    client_id        int     not null references pharmacy.clients(client_id) on delete restrict,
    medicine_id      int     not null references pharmacy.medicines(medicine_id) on delete restrict,
    issue_date       date    not null,
    expiry_date      date    not null
);

create table if not exists pharmacy.batches (
    batch_id       serial  primary key,
    medicine_id    int     not null references pharmacy.medicines(medicine_id) on delete cascade,
    supplier_id    int     not null references pharmacy.suppliers(supplier_id) on delete restrict,
    quantity       int     not null,
    delivery_date  date    not null
);

create table if not exists pharmacy.sales (
    sale_id    serial    primary key,
    client_id  int       references pharmacy.clients(client_id) on delete set null,
    sale_date  timestamp default now()
);

create table if not exists pharmacy.sale_items (
    sale_item_id  serial         primary key,
    sale_id       int            not null references pharmacy.sales(sale_id) on delete cascade,
    medicine_id   int            not null references pharmacy.medicines(medicine_id) on delete restrict,
    quantity      int            not null,
    unit_price    numeric(10,2)  not null
);

-- ============================================================================
-- PART 3: ALTER TABLE OPERATIONS
-- ============================================================================

alter table pharmacy.clients add column if not exists phone_number varchar(15);

alter table pharmacy.medicines alter column is_prescription_required set default false;

alter table pharmacy.doctors add constraint check_doctor_specialization 
    check (specialization in ('General', 'Cardiologist', 'Pediatrician', 'Neurologist'));

alter table pharmacy.batches add constraint check_batch_quantity check (quantity >= 0);

alter table pharmacy.batches add constraint check_delivery_date check (delivery_date > date '2026-01-01');

alter table pharmacy.doctors add constraint uq_doctor_license unique (license_number);

alter table pharmacy.clients add constraint uq_client_email unique (email);

alter table pharmacy.prescriptions add constraint check_expiry_after_issue check (expiry_date > issue_date);

-- ============================================================================
-- PART 4: TRUNCATE (Reset tables before data seeding)
-- ============================================================================

truncate 
    pharmacy.sale_items, pharmacy.sales, pharmacy.batches, 
    pharmacy.prescriptions, pharmacy.medicines, pharmacy.suppliers, 
    pharmacy.doctors, pharmacy.clients 
restart identity cascade;

-- ============================================================================
-- PART 5: INSERT INTO (Data seeding via subqueries)
-- ============================================================================

insert into pharmacy.clients (full_name, email, phone_number) values
('Ivan Ivanov',       'ivan@example.kz',    '+77011112233'),
('Maria Petrova',     'maria@example.kz',   '+77022223344'),
('Alexey Smirnov',    'alex@example.kz',    '+77033334455'),
('Elena Kuznetsova',  'elena@example.kz',   '+77044445566'),
('Dmitry Popov',      'dmitry@example.kz',  '+77055556677');

insert into pharmacy.doctors (full_name, license_number, specialization) values
('Dr. Askar Serikov',      'LIC-100200', 'General'),
('Dr. Zarina Akhmetova',   'LIC-300400', 'Cardiologist'),
('Dr. Vladimir Kim',       'LIC-500600', 'Pediatrician'),
('Dr. Dinara Alieva',      'LIC-700800', 'Neurologist'),
('Dr. Ruslan Omarov',      'LIC-900100', 'General');

insert into pharmacy.suppliers (company_name, email, phone) values
('Europharma Supply',   'opt@europharma.kz',    '+77273332211'),
('MedService Almaty',   'info@medservice.kz',   '+77274445566'),
('KazPharm Dist',       'sales@kazpharm.kz',    '+77172555666'),
('Salamat Wholesale',   'salamat@example.kz',   '+77252998877'),
('PharmaLine KZ',       'line@pharmaline.kz',   '+77122445566');

insert into pharmacy.medicines (medicine_name, active_ingredient, base_price, is_prescription_required) values
('Paracetamol Tab',    'Paracetamol',              150.00,   false),
('Ibuprofen Forte',    'Ibuprofen',                450.00,   false),
('Aspirin Cardio',     'Acetylsalicylic acid',    1200.00,   false),
('Amoxiclav 1000',     'Amoxicillin',             3200.00,   true),
('Captopril STI',      'Captopril',                250.00,   true),
('Sumamed 500',        'Azithromycin',            4100.00,   true),
('No-Spa',             'Drotaverine',              850.00,   false),
('Losartan Richter',   'Losartan',                1800.00,   true),
('Ceftriaxone Pwd',    'Ceftriaxone',              600.00,   true),
('Linex Caps',         'Lactobacillus',           2900.00,   false),
('Analgin',            'Metamizole sodium',        100.00,   false);


insert into pharmacy.prescriptions (doctor_id, client_id, medicine_id, issue_date, expiry_date) values
((select doctor_id from pharmacy.doctors where license_number = 'LIC-300400'), (select client_id from pharmacy.clients where email = 'maria@example.kz'), (select medicine_id from pharmacy.medicines where medicine_name = 'Amoxiclav 1000'), '2026-02-10', '2026-03-10'),
((select doctor_id from pharmacy.doctors where license_number = 'LIC-700800'), (select client_id from pharmacy.clients where email = 'elena@example.kz'), (select medicine_id from pharmacy.medicines where medicine_name = 'Losartan Richter'), '2026-03-01', '2026-04-01'),
((select doctor_id from pharmacy.doctors where license_number = 'LIC-100200'), (select client_id from pharmacy.clients where email = 'ivan@example.kz'), (select medicine_id from pharmacy.medicines where medicine_name = 'Captopril STI'), '2026-01-15', '2026-02-15'),
((select doctor_id from pharmacy.doctors where license_number = 'LIC-500600'), (select client_id from pharmacy.clients where email = 'alex@example.kz'), (select medicine_id from pharmacy.medicines where medicine_name = 'Sumamed 500'), '2026-04-20', '2026-05-20'),
((select doctor_id from pharmacy.doctors where license_number = 'LIC-900100'), (select client_id from pharmacy.clients where email = 'dmitry@example.kz'), (select medicine_id from pharmacy.medicines where medicine_name = 'Ceftriaxone Pwd'), '2026-05-01', '2026-06-01');

insert into pharmacy.batches (medicine_id, supplier_id, quantity, delivery_date) values
((select medicine_id from pharmacy.medicines where medicine_name = 'Amoxiclav 1000'), (select supplier_id from pharmacy.suppliers where email = 'opt@europharma.kz'), 150, '2026-02-15'),
((select medicine_id from pharmacy.medicines where medicine_name = 'Paracetamol Tab'), (select supplier_id FROM pharmacy.suppliers WHERE email = 'info@medservice.kz'), 2000, '2026-01-10'),
((select medicine_id from pharmacy.medicines where medicine_name = 'Aspirin Cardio'), (select supplier_id from pharmacy.suppliers where email = 'sales@kazpharm.kz'), 500, '2026-03-22'),
((select medicine_id from pharmacy.medicines where medicine_name = 'No-Spa'), (select supplier_id from pharmacy.suppliers where email = 'line@pharmaline.kz'), 800, '2026-04-05'),
((select medicine_id from pharmacy.medicines where medicine_name = 'Sumamed 500'), (select supplier_id from pharmacy.suppliers where email = 'salamat@example.kz'), 120, '2026-05-12');

insert into pharmacy.sales (client_id, sale_date) values
((select client_id from pharmacy.clients where email = 'ivan@example.kz'),   '2026-02-18 10:30:00'),
((select client_id from pharmacy.clients where email = 'maria@example.kz'),  '2026-02-20 14:15:00'),
((select client_id from pharmacy.clients where email = 'alex@example.kz'),   '2026-03-05 18:45:00'),
((select client_id from pharmacy.clients where email = 'elena@example.kz'),  '2026-04-01 09:00:00'),
(null,                                                                       '2026-04-12 12:00:00');

insert into pharmacy.sale_items (sale_id, medicine_id, quantity, unit_price)
select s.sale_id, m.medicine_id, 2, m.price_with_vat
from pharmacy.sales s join pharmacy.clients c on s.client_id = c.client_id cross join pharmacy.medicines m
where c.email = 'ivan@example.kz' and m.medicine_name in ('Paracetamol Tab', 'No-Spa');

insert into pharmacy.sale_items (sale_id, medicine_id, quantity, unit_price) values
((select sale_id from pharmacy.sales where sale_date = '2026-02-20 14:15:00'), (select medicine_id from pharmacy.medicines where medicine_name = 'Amoxiclav 1000'), 1, 3584.00),
((select sale_id from pharmacy.sales where sale_date = '2026-02-20 14:15:00'), (select medicine_id from pharmacy.medicines where medicine_name = 'Ibuprofen Forte'), 3, 504.00),
((select sale_id from pharmacy.sales where sale_date = '2026-03-05 18:45:00'), (select medicine_id from pharmacy.medicines where medicine_name = 'Aspirin Cardio'), 1, 1344.00),
((select sale_id from pharmacy.sales where sale_date = '2026-04-01 09:00:00'), (select medicine_id from pharmacy.medicines where medicine_name = 'Losartan Richter'), 2, 2016.00),
((select sale_id from pharmacy.sales where sale_date = '2026-04-12 12:00:00'), (select medicine_id from pharmacy.medicines where medicine_name = 'Analgin'), 5, 112.00),
((select sale_id from pharmacy.sales where sale_date = '2026-04-12 12:00:00'), (select medicine_id from pharmacy.medicines where medicine_name = 'Linex Caps'), 1, 3248.00),
((select sale_id from pharmacy.sales where sale_date = '2026-03-05 18:45:00'), (select medicine_id from pharmacy.medicines where medicine_name = 'No-Spa'), 2, 952.00),
((select sale_id from pharmacy.sales where sale_date = '2026-04-01 09:00:00'), (select medicine_id from pharmacy.medicines where medicine_name = 'Ibuprofen Forte'), 1, 504.00);

-- ============================================================================
-- PART 6: UPDATE OPERATIONS
-- ============================================================================

update pharmacy.medicines set base_price = base_price * 1.05 where is_prescription_required = false;

update pharmacy.sale_items si set unit_price = m.price_with_vat
from pharmacy.medicines m where si.medicine_id = m.medicine_id;

-- ============================================================================
-- PART 7: DELETE OPERATIONS (Safe execution)
-- ============================================================================

delete from pharmacy.prescriptions where expiry_date < date '2026-02-15'
returning prescription_id, client_id, expiry_date;

-- ============================================================================
-- PART 8: ROLES AND PRIVILEGES
-- ============================================================================

drop role if exists pharmacy_readonly;
drop role if exists pharmacy_writer;

create role pharmacy_readonly;
grant usage on schema pharmacy to pharmacy_readonly;
grant select on all tables in schema pharmacy to pharmacy_readonly;

create role pharmacy_writer;
grant usage on schema pharmacy to pharmacy_writer;
grant insert, update on pharmacy.sales to pharmacy_writer;
grant insert on pharmacy.sale_items to pharmacy_writer;

revoke update on pharmacy.sales from pharmacy_writer;
