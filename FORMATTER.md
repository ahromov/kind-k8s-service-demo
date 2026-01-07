# Prettier + Spotless + Husky v9 Pre-Commit Hook

### Ця інструкція дозволяє автоматично форматувати файли під час git commit:

- Prettier → YAML, JSON, HTML, CSS, Markdown, JS, etc.
- Spotless + Google Java Format → Java-код
- Husky v9 → pre-commit хук
- lint-staged → форматує тільки staged файли

## 1. Встановити Node/npm(якщо немає) після чого залежності в корні проекту

```bash
npm init -y
npm install --save-dev prettier husky lint-staged
```

## 2. Ініціалізувати Husky v9+

```bash
npx husky init
```

## 3. Зробити виконавчим (через Git Bash / WSL / Linux):

```bash
chmod +x .husky/pre-commit
```

та додати в файл код:

```text
#!/usr/bin/env sh

echo ">>> HUSKY PRE-COMMIT RUNS"
npx lint-staged
```

## 4 Перевірити роботу

В окремій гілці внести зміни. Виконати команди

```bash
git add .
```

```bash
git commit -m "test"
```

Має зʼявитися в консолі:

```text
>>> HUSKY PRE-COMMIT RUNS
[STARTED] prettier --write
[STARTED] npm run spotless:apply
...
[COMPLETED]
```
