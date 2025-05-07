- name: Run PowerShell Script on Windows
  hosts: windows
  tasks:
    - name: Ensure C:\Temp exists
      win_file:
        path: C:\Temp
        state: directory

    - name: Copy PowerShell script to remote host
      win_copy:
        src: files/WinPatches.ps1
        dest: C:\Temp\WinPatches.ps1

    - name: Execute the PowerShell script
      win_shell: powershell.exe -ExecutionPolicy Bypass -File "C:\Temp\WinPatches.ps1"
