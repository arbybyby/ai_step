чтобы зайти в базу: docker exec -it ais-db psql -U ais -d ais-db

\dt — список всех таблиц (проверь, прошли ли миграции).

\du — список пользователей и их ролей.

SELECT \* FROM users; — посмотреть список созданных пользователей.

\q — выход из терминала базы.

рандомный челик

INSERT INTO admins ("Email", "FirstName", "LastName", "PasswordHash" ) VALUES ( 'golubenkokirill@gmail.com', 'Kirill', 'Golubenko', '$2a$10$5DIZVYhksizgNamu8KfS/eWc.uNk40jJOiWJehYjg58tlyAAf1O4e');

DELETE FROM admins WHERE "Email" = 'golubenkokirill@gmail.com';

логин golubenkokirill@gmail.com
пароль securepassword123
