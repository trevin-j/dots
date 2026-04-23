---
name: migrations
description: Guide through tasks where database migrations must be added. Use when users ask to add migrations, run migrations, rollback changes, or modify database schema.
author: DevTrev
license: MIT
---

# Database Migrations

Always add migrations via the official CLI rather than hand-writing filenames or raw SQL.

## Core Principles

- Use official migration tools - never hand-edit migration file names
- Always generate a rollback path before applying migrations
- Test migrations against a copy of production data when possible
- Never run migrations directly against production without verification

## Common Migration Tools

### Python

**Alembic (SQLAlchemy)**
```bash
alembic revision --autogenerate -m "description"
alembic upgrade head
alembic downgrade -1
alembic history
```

**Django**
```bash
python manage.py makemigrations
python manage.py migrate
python manage.py showmigrations
```

### Node.js

**TypeORM**
```bash
typeorm migration:generate -n Description
typeorm migration:run
typeorm migration:revert
```

**Prisma**
```bash
prisma migrate dev --name description
prisma migrate deploy
prisma migrate reset
```

### Go

**golang-migrate**
```bash
migrate -database DATABASE_URL -path ./migrations up
migrate -database DATABASE_URL -path ./migrations down 1
```

**GORM**
```bash
# Use gorm automigrate or explicit migrations in code
```

### Ruby on Rails

```bash
rails generate migration AddColumnToTable column_name:data_type
rails db:migrate
rails db:rollback
rails db:migrate:status
```

### Java

**Flyway**
```bash
flyway -url=jdbc:... migrate
flyway -url=jdbc:... info
flyway -url=jdbc:... undo
```

**Liquibase**
```bash
liquibase update
liquibase rollback count=1
liquibase status
```

## Workflow

1. **Generate** - Use the CLI to create a migration file with a descriptive name
2. **Review** - Inspect the generated migration before applying
3. **Test** - Run against a staging/development environment first
4. **Backup** - Ensure there's a database backup before production migration
5. **Apply** - Run migration with verification steps
6. **Verify** - Confirm the migration succeeded and data is intact

## Rollback Patterns

Always document how to undo a migration:

```sql
-- Forward
ALTER TABLE users ADD COLUMN email VARCHAR(255);

-- Rollback
ALTER TABLE users DROP COLUMN email;
```

For data migrations, include both up and down logic:

```sql
-- up
UPDATE users SET email = lower(username) || '@example.com' WHERE email IS NULL;

-- down (if possible)
-- Note: Cannot restore original NULL values if they were lost
```

## Multi-Environment Strategy

| Environment | Action |
|-------------|--------|
| Development | Run freely, reset often |
| Staging | Mirror production config, test migrations |
| Production | Backup first, apply during low-traffic window, have rollback plan |

## When Migration Fails

1. Check the error message for the specific failure
2. Most failures are due to:
   - Constraint violations (duplicate keys, null constraints)
   - Lock timeouts on large tables
   - Connection issues
3. Fix the migration or create a new one to handle the case
4. Never manually modify migration history in shared databases

## Red Flags

- Migration files with timestamps hand-edited
- Direct INSERT/UPDATE to migration tables
- Migrations that delete columns with data without warning
- Missing rollback documentation
