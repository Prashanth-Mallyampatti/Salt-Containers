# File Description and Comments

**This folder has the necessary files required to buils a *salt-minion* container.**

1. **`Dockerfile`**: 
    - File to build openSUSE docker image with *salt-minion* installed and suport for *systemd*.
    
2. **`salt-minion.sh`**:
    - It avoids zombie salt-minion processes because bash implements basic signal handling. It will also perform a cleanup when the process dies, and waits for 5 seconds.
    
