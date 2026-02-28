# Bash User Management System
Multiple Bash scripts combined to create a great user management tool.

## Modular CLI Application with Sandboxed Shell & Terminal Game

A modular **Command Line Interface (CLI)** application written entirely in **Bash**, implementing:

   - User registration & authentication  
   - Isolated per-user shell environments  
   - File system usage reporting  
   - Interactive Archery mini-game  

Designed to demonstrate structured shell scripting, process control, and secure directory isolation.

---

## ▶️ Execution

```bash
chmod +x *.sh
./meniu.sh
```

## _meniu.sh_ — Application Controller

 - Arrow-based interactive menu (↑ ↓)
 - Session overview display
 - Central dispatcher for all modules
 - ANSI-styled terminal interface

 ### MENU 


<img width="940" height="846" alt="Screenshot 2026-02-28 210711" src="https://github.com/user-attachments/assets/20a910ae-adc2-4e3f-978f-0388d3d206b2" />

## _creare.sh_ — User Registration Module

Handles:
 - Username validation (regex-based)
 - Email validation
 - SHA-256 password hashing
 - Unique ID generation
 - Automatic directory creation

 ### USER CREATION 


<img width="781" height="1144" alt="Screenshot 2026-02-28 212435" src="https://github.com/user-attachments/assets/6a4c7093-0f51-4f0e-a4fc-09289e19bc71" />



## _operatiuni.sh_ — Authentication & Sandboxed Shell

Implements:
 - Login with hash verification (max 3 attempts)
 - Session tracking (active users array)
 - Logout mechanism
 - Last login timestamp update

Sandboxed Terminal:
 - Each authenticated user receives a restricted interactive Bash shell:
 - Navigation limited to personal directory
 - Overridden cd command
 - Path validation using realpath
 - Custom colored prompt
 - Secure return to main menu

### LOGIN 


<img width="641" height="1091" alt="Screenshot 2026-02-28 212650" src="https://github.com/user-attachments/assets/ad4df339-d668-4e3b-a1d1-f886d73af612" />


### LOGOUT


<img width="942" height="611" alt="Screenshot 2026-02-28 213138" src="https://github.com/user-attachments/assets/42a9ffa9-e4e1-4863-80c1-a40448a46baa" />


### USER STATUS 


<img width="555" height="314" alt="Screenshot 2026-02-28 212726" src="https://github.com/user-attachments/assets/b91fc0e8-1a9a-4fb2-acbc-aced9299de68" />


## _raport.sh_ — Usage Report Generator

Generates a structured report including:
 - Total number of files
 - Total number of directories
 - Disk usage (KB)
 - Generation timestamp

### REPORT GENERATOR 


<img width="579" height="876" alt="Screenshot 2026-02-28 212911" src="https://github.com/user-attachments/assets/4c064ba0-4892-4979-a2f9-ecf11ba6a83a" />

## _archery.sh_ — Terminal Archery Game

A fully interactive mini-game built purely in Bash.

Features:
 - 5 rounds per session
 - Press SPACE to release
 - Random wind deviation (−2 to +2)
 - Target scoring system (🎯 = 100 points)
 - Persistent leaderboard
 - Sorted ranking display

### ARCHERY MINI GAME 


<img width="516" height="194" alt="Screenshot 2026-02-28 212925" src="https://github.com/user-attachments/assets/4b2e55b6-0723-4bd8-ad55-9b51dd0753d1" />


<img width="1258" height="538" alt="Screenshot 2026-02-28 213018" src="https://github.com/user-attachments/assets/482c9d5b-eb7f-4756-a36f-216c5e49a9a5" />


<img width="825" height="415" alt="Screenshot 2026-02-28 213034" src="https://github.com/user-attachments/assets/a01c7620-fc11-44cd-bfa8-be1cc64a104e" />
