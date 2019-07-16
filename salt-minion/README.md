# File Description and Comments

**This folder has the necessary files required to buils a *salt-minion* container.**

1. **`Dockerfile`**: 
    - File to build openSUSE docker image with *salt-minion* installed from *scratch* with various functionalities included.
    
2. **`salt-minion.sh`**:
    - It avoids zombie salt-minion processes because bash implements basic signal handling. It will also perform a cleanup when the process dies, and waits for 5 seconds.
    
3. **`openSUSE-Leap....tar.xv`**:
    - Tar files of openSUSE for various system archtitectures of version *42.3*. Please change the *Dockerfile* accordingly. Currently the Dockerfile includes *x86 64* architecture. 
