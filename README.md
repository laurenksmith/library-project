# 2-Tier Deployment of ‘Library’ Java Spring Boot App

- [2-Tier Deployment of ‘Library’ Java Spring Boot App](#2-tier-deployment-of-library-java-spring-boot-app)
  - [🧭 Overview](#-overview)
  - [🧩 Key Technologies \& Concepts](#-key-technologies--concepts)
  - [⚙️ Step 1 – Create Private GitHub Repo](#️-step-1--create-private-github-repo)
    - [🪜 Actions Taken](#-actions-taken)
  - [⚙️ Step 2 – Deploying App \& Database Locally (Windows + Git Bash)](#️-step-2--deploying-app--database-locally-windows--git-bash)
    - [🧰 Tools Used](#-tools-used)
    - [✅ 2.0 Open the Project](#-20-open-the-project)
    - [✅ 2.1 Verify Java 17 is Installed](#-21-verify-java-17-is-installed)
    - [✅ 2.2 Ensure MySQL Client is on PATH](#-22-ensure-mysql-client-is-on-path)
    - [✅ 2.3 Check MySQL Server is Running](#-23-check-mysql-server-is-running)
    - [✅ 2.4 Create Database + App User](#-24-create-database--app-user)
    - [✅ 2.5 Seed Database from `library.sql`](#-25-seed-database-from-librarysql)
    - [✅ 2.6 Install Maven (Wrapper Missing)](#-26-install-maven-wrapper-missing)
    - [✅ 2.7 Set Environment Variables](#-27-set-environment-variables)
    - [✅ 2.8 Run the Application](#-28-run-the-application)
    - [💤 Optional – Run in Background](#-optional--run-in-background)
    - [🧩 Troubleshooting and Fixes](#-troubleshooting-and-fixes)
    - [🎯 Why This Step Matters](#-why-this-step-matters)
    - [🌱 Benefits](#-benefits)

## 🧭 Overview

This project demonstrates the 2-tier deployment of a **Java Spring Boot application** connected to a **MySQL database**.  
The overall goal is to understand how backend applications communicate with databases, and how to deploy, manage and automate that connection through various methods — including **local setup**, **virtualisation**, and **containerisation**.

This document is a **working technical guide**, designed to be:
- A record of every step I took to implement and troubleshoot the app.
- A reusable instruction manual for future me (and future colleagues) to follow and recreate.
- A reflective log explaining **why** each step is done, and the **benefits** it provides — both for myself as a DevOps engineer and for the Home Office as an organisation.
- Usually, I would include my **troubleshooting** section right near the end of the document. However - due to the size of this project, I have made the decision to include a troubleshooting section for each step, so that it is easier to troubleshoot issues when using this guide.

## 🧩 Key Technologies & Concepts

| Technology | Description | Why It’s Used |
|-------------|-------------|----------------|
| **Java 17 (Spring Boot)** | Backend framework for building APIs and handling business logic. | Provides structure, dependency management, and simplifies deployment. |
| **MySQL 8.0** | Relational database used to store and retrieve application data. | Stable, widely supported and integrates well with Java applications. |
| **Maven** | Build automation and dependency management tool for Java projects. | Handles build lifecycle, compiles code and runs the app via `mvn spring-boot:run`. |
| **GitHub** | Source control repository. | Keeps code versioned, organised and shareable. |
| **Environment Variables** | Secure way to configure credentials (DB host, user, password). | Prevents hard-coding of sensitive data. |
| **cURL** | Command-line tool to test API endpoints. | Quickly checks if the app is returning data correctly. |

## ⚙️ Step 1 – Create Private GitHub Repo

### 🪜 Actions Taken

Absolutely, Lauren 🌟 — here’s your **Step 2** section in perfectly formatted Markdown, ready to paste straight into your `README.md` in VS Code.
It keeps your consistent style (clear headings, Bash syntax highlighting, explanations, and tables) so it will slot in neatly with Step 1 and future sections.

## ⚙️ Step 2 – Deploying App & Database Locally (Windows + Git Bash)

> **Goal:** Run the Spring Boot app in `LibraryProject2` talking to a local MySQL database seeded by `library.sql`.

### 🧰 Tools Used
- **Git Bash** (main terminal)
- **PowerShell** (for Windows package installs only)
- **MySQL Workbench** (to start/stop the server)

### ✅ 2.0 Open the Project
```bash
# Open Git Bash
cd "/c/Users/laure/github/library-java17-mysql-app"
ls
# Expect to see: LibraryProject2  library.sql
````

### ✅ 2.1 Verify Java 17 is Installed

```bash
java -version
```

**Expect:** `openjdk version "17.x"`

If Java 17 is missing:

1. Download and install Temurin JDK 17.
2. Re-open Git Bash, then (optional):

```bash
export JAVA_HOME="/c/Program Files/Eclipse Adoptium/jdk-17"
export PATH="$JAVA_HOME/bin:$PATH"
java -version
```

### ✅ 2.2 Ensure MySQL Client is on PATH

```bash
mysql --version   # will show 'command not found' if not set
export PATH="$PATH:/c/Program Files/MySQL/MySQL Server 8.0/bin"
mysql --version   # should now print Ver 8.0.xx for Win64
```

Persist for future sessions:

```bash
echo 'export PATH="$PATH:/c/Program Files/MySQL/MySQL Server 8.0/bin"' >> ~/.bashrc
source ~/.bashrc
```

### ✅ 2.3 Check MySQL Server is Running

```bash
winpty mysql -u root -p -e "SELECT VERSION();"
```

* If it prints a version → ✅ running
* If refused → start the server:

**Option A (Workbench):**
Open *MySQL Workbench → Server Status → Start Server*

**Option B (Windows service):**

```bash
net start MySQL80
net start "MySQL Server 8.0"
```

### ✅ 2.4 Create Database + App User

> **Use root password when prompted.**
> App user password is for the application (e.g. `StrongPass123!`).

```bash
APP_DB_PASS='StrongPass123!'
winpty mysql -u root -p -e "\
CREATE DATABASE IF NOT EXISTS library; \
CREATE USER IF NOT EXISTS 'appuser'@'localhost' IDENTIFIED BY '${APP_DB_PASS}'; \
GRANT ALL PRIVILEGES ON library.* TO 'appuser'@'localhost'; \
FLUSH PRIVILEGES;"
```

### ✅ 2.5 Seed Database from `library.sql`

```bash
cd "/c/Users/laure/github/library-java17-mysql-app"
cat library.sql | mysql -u appuser -p -D library
# Enter the appuser password (StrongPass123!)
```

Alternative (no prompt):

```bash
mysql -u appuser -p'StrongPass123\!' library < library.sql
```

Verify:

```bash
mysql -u appuser -p -e "USE library; SHOW TABLES;"
```

### ✅ 2.6 Install Maven (Wrapper Missing)

1. Download **Apache Maven binary ZIP** (e.g. `apache-maven-3.9.x-bin.zip`).
2. Extract to:

```
C:\Program Files\Apache\maven-3.9.x
```

3. In Git Bash:

```bash
export M2_HOME="/c/Program Files/Apache/maven-3.9.x"
export PATH="$M2_HOME/bin:$PATH"
mvn -version
```

Persist:

```bash
echo 'export M2_HOME="/c/Program Files/Apache/maven-3.9.x"' >> ~/.bashrc
echo 'export PATH="$M2_HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### ✅ 2.7 Set Environment Variables

```bash
export DB_HOST='jdbc:mysql://127.0.0.1:3306/library?allowPublicKeyRetrieval=true&useSSL=false'
export DB_USER='appuser'
export DB_PASS='StrongPass123!'

export SPRING_DATASOURCE_URL="$DB_HOST"
export SPRING_DATASOURCE_USERNAME="$DB_USER"
export SPRING_DATASOURCE_PASSWORD="$DB_PASS"

echo "$DB_HOST"
```

Persist to future sessions:

```bash
echo 'export DB_HOST="jdbc:mysql://127.0.0.1:3306/library?allowPublicKeyRetrieval=true&useSSL=false"' >> ~/.bashrc
echo 'export DB_USER="appuser"' >> ~/.bashrc
echo 'export DB_PASS="StrongPass123!"' >> ~/.bashrc
```

### ✅ 2.8 Run the Application

```bash
cd "/c/Users/laure/github/library-java17-mysql-app/LibraryProject2"
mvn spring-boot:run
```

**Expect log output:**

```
Tomcat started on port(s): 5000 (http)
HikariPool-1 – Added connection com.mysql.cj.jdbc.ConnectionImpl...
Started LibraryProject2Application ...
```

**Test the endpoint:**

```bash
curl -i http://localhost:5000/authors
```

Or open [http://localhost:5000/authors](http://localhost:5000/authors) in a browser.

Stop the app:

```
CTRL + C
```

### 💤 Optional – Run in Background

```bash
cd "/c/Users/laure/github/library-java17-mysql-app/LibraryProject2"
mvn spring-boot:start
# ... later
mvn spring-boot:stop
```

### 🧩 Troubleshooting and Fixes

| Symptom                            | Cause                           | Fix                                                                |            |
| ---------------------------------- | ------------------------------- | ------------------------------------------------------------------ | ---------- |
| `mysql: command not found`         | MySQL not on PATH               | `export PATH="$PATH:/c/Program Files/MySQL/MySQL Server 8.0/bin"`  |            |
| MySQL service not found            | Different service name          | Started via Workbench → Server Status → Start Server               |            |
| Root vs Appuser password confusion | Prompt doesn’t say which        | Root for admin, appuser for app — reset via `ALTER USER` if needed |            |
| `stdin is not a tty` on import     | Used `winpty` with `< file.sql` | Use `cat library.sql                                               | mysql ...` |
| `mvn: command not found`           | Maven not installed             | Install Maven + add to PATH                                        |            |
| `URL must start with 'jdbc'`       | Env var missing                 | Set `DB_HOST` and `SPRING_DATASOURCE_*`                            |            |
| `Public Key Retrieval not allowed` | MySQL 8 auth nuance             | Add `allowPublicKeyRetrieval=true&useSSL=false`                    |            |
| 404 at root URL                    | No route at `/`                 | Use `/authors` endpoint                                            |            |

---

### 🎯 Why This Step Matters

* Simulates a real 2-tier stack (app ↔ DB) locally.
* Builds skills in config, auth, and diagnostics via logs.
* Provides a known-good baseline before VM, Ansible or Docker deployment.

---

### 🌱 Benefits

| Perspective             | Benefit                                                                               |
| ----------------------- | ------------------------------------------------------------------------------------- |
| **For me (Developer)**  | Hands-on practice linking Java and MySQL, managing env vars and builds via Maven.     |
| **For the Home Office** | Reliable, repeatable setup ensuring secure DB connections and better maintainability. |

