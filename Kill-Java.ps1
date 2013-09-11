<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Kill-Java
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true)]
        $Param1,

        # Log defaults to "$env:SystemDrive\Logs\$env:COMPUTERNAME Java Runtime Removal.log"
        $Log="$env:SystemDrive\Logs\$env:COMPUTERNAME Java Runtime Removal.log",

        # Force
        $Force=$true,

        # Reinstall Java? crazy...
        $Reinstall=$false,

        # Java Install file and location, formated with x64.exe or x86.exe at the end. Have both in the same folder.
        $JavaBin=".\java-x64.exe",

        #Java Arg, defaults to "/s /v'ADDLOCAL=ALL IEXPLORER=1 MOZILLA=1 JAVAUPDATE=0 REBOOT=suppress' /qn"
        $JavaArgs="/s /v'ADDLOCAL=ALL IEXPLORER=1 MOZILLA=1 JAVAUPDATE=0 REBOOT=suppress' /qn"
    )

    Begin
    {
        $force_exitcode="1618"
        $Version="1.5.0"
        $Updated="2013-07-23"
        $Title="Java Runtime Nuker v$Version ($Updated)"
        $arch=$env:PROCESSOR_ARCHITECTURE

        # Clear log and create log dir if it's not there
        $mkdirs = $Log.Substring(0,$Log.Length - $Log.split('\')[$Log.split('\').Count - 1].Length)
        mkdir $mkdirs -ErrorAction SilentlyContinue
        Clear-Content $Log -ErrorAction SilentlyContinue

        Write-Output ""
        Write-Output " JAVA RUNTIME NUKER"
        Write-Output " v$Version, updated $Updated"
        if %OS_VERSION%==XP Write-Output "" && Write-Output " ! Windows XP detected, using alternate command set to compensate."
        Write-Output ""
        Write-Output "$(Get-Date)   Beginning removal of Java Runtime Environments (series 3-7, x86 and x64) and JavaFX..." | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   Beginning removal of Java Runtime Environments (series 3-7, x86 and x64) and JavaFX..."

        #Do a quick check to make sure WMI is working, and if not, repair it
        wmic timezone >NUL
        if not %ERRORLEVEL%==0 (
            Write-Output "$(Get-Date) ! WMI appears to be broken. Running WMI repair. This might take a minute, please be patient..." | Out-File -FilePath $Log -Append
            Write-Output "$(Get-Date) ! WMI appears to be broken. Running WMI repair. This might take a minute, please be patient..."
            net stop winmgmt
            pushd $env:windir\system32\wbem
            for %%i in (*.dll) do RegSvr32 -s %%i
            #Kill this random window that pops up
            tskill wbemtest /a 2>NUL
            scrcons.exe /RegServer
            unsecapp.exe /RegServer
            start "" wbemtest.exe /RegServer
            tskill wbemtest /a 2>NUL
            tskill wbemtest /a 2>NUL
            winmgmt.exe /RegServer
            wmiadap.exe /RegServer
            wmiapsrv.exe /RegServer
            wmiprvse.exe /RegServer
            net start winmgmt
            popd
        )


        #########
        #FORCE-CLOSE PROCESSES #-- Do we want to kill Java before running? If so, this is where it happens
        #########
        if %FORCE_CLOSE_PROCESSES%==yes (
	        #Kill all browsers and running Java instances
	        Write-Output "$(Get-Date)   Looking for and closing all running browsers and Java instances..." | Out-File -FilePath $Log -Append
	        Write-Output "$(Get-Date)   Looking for and closing all running browsers and Java instances..."
	        if %OS_VERSION%==XP (
		        #XP version of the task killer
		        #this loop contains the processes we should kill
		        Write-Output ""
		        FOR %%i IN (java,javaw,javaws,jqs,jusched,iexplore,iexplorer,firefox,chrome,palemoon) DO (
			        Write-Output "Searching for %%i.exe..."
			        tskill /a /v %%i | Out-File -FilePath $Log -Append 2>NUL
		        )
		        Write-Output ""
	        ) else (
		        #7/8/2008/2008R2/2012/etc version of the task killer
		        #this loop contains the processes we should kill
		        Write-Output ""
		        FOR %%i IN (java,javaw,javaws,jqs,jusched,iexplore,iexplorer,firefox,chrome,palemoon) DO (
			        Write-Output "Searching for %%i.exe..."
			        taskkill /f /im %%i.exe /T | Out-File -FilePath $Log -Append 2>NUL
		        )
		        Write-Output ""
	        )
        )

        #If we DON'T want to force-close Java, then check for possible running Java processes and abort the script if we find any
        if %FORCE_CLOSE_PROCESSES%==no (
	        Write-Output "$(Get-Date)   Variable FORCE_CLOSE_PROCESSES is set to '%FORCE_CLOSE_PROCESSES%'. Checking for running processes before execution." | Out-File -FilePath $Log -Append
	        Write-Output "$(Get-Date)   Variable FORCE_CLOSE_PROCESSES is set to '%FORCE_CLOSE_PROCESSES%'. Checking for running processes before execution."
<#
	        #Don't ask...
	        #Okay so basically we loop through this list of processes, and for each one we dump the result of the search in the %%a variable. 
	        #Then we check that variable, and if it's not null (e.g. FIND.exe found something) we abort the script, returning the exit code
	        #specified at the beginning of the script. Normally you'd use ERRORLEVEL for this, but because it is very flaky (it doesn't 
	        #always get set, even when it should) we instead resort to using this method of dumping the results in a variable and checking it.
#>
	        FOR %%i IN (java,javaw,javaws,jqs,jusched,iexplore,iexplorer,firefox,chrome,palemoon) DO (
		        Write-Output "$(Get-Date)   Searching for %%i.exe..."
		        for /f "delims=" %%a in ('tasklist ^| find /i "%%i"') do (
			        if not [%%a]==[] (
				        Write-Output "$(Get-Date) ! ERROR: Process '%%i' is currently running, aborting." | Out-File -FilePath $Log -Append
				        Write-Output "$(Get-Date) ! ERROR: Process '%%i' is currently running, aborting."
				        exit $force_exitcode
			        )
		        )
	        )
	        #If we made it this far, we didn't find anything, so we can go ahead
	        Write-Output "$(Get-Date)   All clear, no running processes found. Going ahead with removal..." | Out-File -FilePath $Log -Append
	        Write-Output "$(Get-Date)   All clear, no running processes found. Going ahead with removal..."
        )


        ########
        #UNINSTALLER SECTION #-- Basically here we just brute-force every "normal" method for
        ########   removing Java, and then resort to more painstaking methods later
        Write-Output "$(Get-Date)   Targeting individual JRE versions..." | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   Targeting individual JRE versions..."
        Write-Output "$(Get-Date)   This might take a few minutes. Don't close this window."

        #Okay, so all JRE runtimes (series 4-7) use product GUIDs, with certain numbers that increment with each new update (e.g. Update 25)
        #This makes it easy to catch ALL of them through liberal use of WMI wildcards ("_" is single character, "%" is any number of characters)
        #Additionally, JRE 6 introduced 64-bit runtimes, so in addition to the two-digit Update XX revision number, we also check for the architecture 
        #type, which always equals '32' or '64'. The first wildcard is the architecture, the second is the revision/update number.

        #JRE 7
        Write-Output "$(Get-Date)   JRE 7..." | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   JRE 7..."
        %WMIC% product where "IdentifyingNumber like '{26A24AE4-039D-4CA4-87B4-2F8__170__FF}'" call uninstall /nointeractive | Out-File -FilePath $Log -Append

        #JRE 6
        Write-Output "$(Get-Date)   JRE 6..." | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   JRE 6..."
        #1st line is for updates 23-xx, after 64-bit runtimes were introduced.
        #2nd line is for updates 1-22, before Oracle released 64-bit JRE 6 runtimes
        %WMIC% product where "IdentifyingNumber like '{26A24AE4-039D-4CA4-87B4-2F8__160__FF}'" call uninstall /nointeractive | Out-File -FilePath $Log -Append
        %WMIC% product where "IdentifyingNumber like '{3248F0A8-6813-11D6-A77B-00B0D0160__0}'" call uninstall /nointeractive | Out-File -FilePath $Log -Append

        #JRE 5
        Write-Output "$(Get-Date)   JRE 5..." | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   JRE 5..."
        %WMIC% product where "IdentifyingNumber like '{3248F0A8-6813-11D6-A77B-00B0D0150__0}'" call uninstall /nointeractive | Out-File -FilePath $Log -Append

        #JRE 4
        Write-Output "$(Get-Date)   JRE 4..." | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   JRE 4..."
        %WMIC% product where "IdentifyingNumber like '{7148F0A8-6813-11D6-A77B-00B0D0142__0}'" call uninstall /nointeractive | Out-File -FilePath $Log -Append

        #JRE 3 (AKA "Java 2 Runtime Environment Standard Edition" v1.3.1_00-25)
        Write-Output "$(Get-Date)   JRE 3 (AKA Java 2 Runtime v1.3.xx)..." | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   JRE 3 (AKA Java 2 Runtime v1.3.xx)..."
        #This version is so old we have to resort to different methods of removing it
        #Loop through each sub-version
        FOR %%i IN (01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25) DO (
	        %SystemRoot%\IsUninst.exe -f"$env:ProgramFiles\JavaSoft\JRE\1.3.1_%%i\Uninst.isu" -a 2>NUL
	        %SystemRoot%\IsUninst.exe -f"${env:ProgramFiles(x86)}\JavaSoft\JRE\1.3.1_%%i\Uninst.isu" -a 2>NUL
        )
        #This one wouldn't fit in the loop above
        %SystemRoot%\IsUninst.exe -f"$env:ProgramFiles\JavaSoft\JRE\1.3\Uninst.isu" -a 2>NUL
        %SystemRoot%\IsUninst.exe -f"${env:ProgramFiles(x86)}\JavaSoft\JRE\1.3\Uninst.isu" -a 2>NUL

        #Wildcard uninstallers
        Write-Output "$(Get-Date)   Specific targeting done. Now running WMIC wildcard catchall uninstallation..." | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   Specific targeting done. Now running WMIC wildcard catchall uninstallation..."
        %WMIC% product where "name like '%%J2SE Runtime%%'" call uninstall /nointeractive | Out-File -FilePath $Log -Append
        %WMIC% product where "name like 'Java%%Runtime%%'" call uninstall /nointeractive | Out-File -FilePath $Log -Append
        %WMIC% product where "name like 'JavaFX%%'" call uninstall /nointeractive | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   Done." | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   Done."


        #######:
        #REGISTRY CLEANUP #-- This is where it gets hairy. Don't read ahead if you have a weak constitution.
        #######:
        #If we're on XP we skip this entire block due to differences in the reg.exe binary
        if '%OS_VERSION%'=='XP' (
            Write-Output "$(Get-Date) ! Registry cleanup doesn't work on Windows XP. Skipping..." | Out-File -FilePath $Log -Append
            Write-Output "$(Get-Date) ! Registry cleanup doesn't work on Windows XP. Skipping..."
	        goto file_cleanup
	        )

        Write-Output "$(Get-Date)   Commencing registry cleanup..." | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   Commencing registry cleanup..."
        Write-Output "$(Get-Date)   Searching for residual registry keys..." | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   Searching for residual registry keys..."

        #Search MSIExec installer class hive for keys
        Write-Output "$(Get-Date)   Looking in HKLM\software\classes\installer\products..." | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   Looking in HKLM\software\classes\installer\products..."
        reg query HKLM\software\classes\installer\products /f "J2SE Runtime" /s | find "HKEY_LOCAL_MACHINE" >> $env:TEMP\java_purge_registry_keys.txt
        reg query HKLM\software\classes\installer\products /f "Java(TM) 6 Update" /s | find "HKEY_LOCAL_MACHINE" >> $env:TEMP\java_purge_registry_keys.txt
        reg query HKLM\software\classes\installer\products /f "Java 7" /s | find "HKEY_LOCAL_MACHINE" >> $env:TEMP\java_purge_registry_keys.txt
        reg query HKLM\software\classes\installer\products /f "Java*Runtime" /s | find "HKEY_LOCAL_MACHINE" >> $env:TEMP\java_purge_registry_keys.txt

        #Search the Add/Remove programs list (this helps with broken Java installations)
        Write-Output "$(Get-Date)   Looking in HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall..." | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   Looking in HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall..."
        reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall /f "J2SE Runtime" /s | find "HKEY_LOCAL_MACHINE" >> $env:TEMP\java_purge_registry_keys.txt
        reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall /f "Java(TM) 6 Update" /s | find "HKEY_LOCAL_MACHINE" >> $env:TEMP\java_purge_registry_keys.txt
        reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall /f "Java 7" /s | find "HKEY_LOCAL_MACHINE" >> $env:TEMP\java_purge_registry_keys.txt
        reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall /f "Java*Runtime" /s | find "HKEY_LOCAL_MACHINE" >> $env:TEMP\java_purge_registry_keys.txt

        #Search the Add/Remove programs list, x86/Wow64 node (this helps with broken Java installations)
        Write-Output "$(Get-Date)   Looking in HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall..." | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   Looking in HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall..."
        reg query HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall /f "J2SE Runtime" /s | find "HKEY_LOCAL_MACHINE" >> $env:TEMP\java_purge_registry_keys.txt
        reg query HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall /f "Java(TM) 6 Update" /s | find "HKEY_LOCAL_MACHINE" >> $env:TEMP\java_purge_registry_keys.txt
        reg query HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall /f "Java 7" /s | find "HKEY_LOCAL_MACHINE" >> $env:TEMP\java_purge_registry_keys.txt
        reg query HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall /f "Java*Runtime" /s | find "HKEY_LOCAL_MACHINE" >> $env:TEMP\java_purge_registry_keys.txt

        #List the leftover registry keys
        Write-Output "$(Get-Date)   Found these keys..." | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   Found these keys..."
        Write-Output "" | Out-File -FilePath $Log -Append
        Write-Output ""
        type $env:TEMP\java_purge_registry_keys.txt" | Out-File -FilePath $Log -Append
        type $env:TEMP\java_purge_registry_keys.txt"
        Write-Output "" | Out-File -FilePath $Log -Append
        Write-Output ""

        #Backup the various registry keys that will get deleted (if they exist)
        #We do this mainly because we're using wildcards, so we want a method to roll back if we accidentally nuke the wrong thing
        Write-Output "$(Get-Date)   Backing up keys..." | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   Backing up keys..."
        if exist "$env:TEMP\java_purge_registry_backup" rmdir /s /q "$env:TEMP\java_purge_registry_backup" 2>NUL
        mkdir $env:TEMP\java_purge_registry_backup >NUL
        #This line walks through the file we generated and dumps each key to a file
        for /f "tokens=* delims= " %%a in ($env:TEMP\java_purge_registry_keys.txt) do (reg query %%a) >> $env:TEMP\java_purge_registry_backup\java_reg_keys_1.bak

        Write-Output ""
        Write-Output "$(Get-Date)   Keys backed up to $env:TEMP\java_purge_registry_backup\ " | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   Keys backed up to $env:TEMP\java_purge_registry_backup\"
        Write-Output "$(Get-Date)   This directory will be deleted at next reboot, so get it now if you need it! " | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   This directory will be deleted at next reboot, so get it now if you need it!"

        #Purge the keys
        Write-Output "$(Get-Date)   Purging keys..." | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   Purging keys..."
        Write-Output ""
        #This line walks through the file we generated and deletes each key listed
        for /f "tokens=* delims= " %%a in ($env:TEMP\java_purge_registry_keys.txt) do reg delete %%a /va /f  | Out-File -FilePath $Log -Append 2>NUL

        #These lines delete some specific Java locations
        #These keys AREN'T backed up because these are specific, known Java keys, whereas above we were nuking
        #keys based on wildcards, so those need backups in case we nuke something we didn't want to.

        #Delete keys for 32-bit Java installations on a 64-bit copy of Windows
        reg delete "HKLM\SOFTWARE\Wow6432Node\JavaSoft\Auto Update" /va /f | Out-File -FilePath $Log -Append 2>NUL
        reg delete "HKLM\SOFTWARE\Wow6432Node\JavaSoft\Java Plug-in" /va /f | Out-File -FilePath $Log -Append 2>NUL
        reg delete "HKLM\SOFTWARE\Wow6432Node\JavaSoft\Java Runtime Environment" /va /f | Out-File -FilePath $Log -Append 2>NUL
        reg delete "HKLM\SOFTWARE\Wow6432Node\JavaSoft\Java Update" /va /f | Out-File -FilePath $Log -Append 2>NUL
        reg delete "HKLM\SOFTWARE\Wow6432Node\JavaSoft\Java Web Start" /va /f | Out-File -FilePath $Log -Append 2>NUL
        reg delete "HKLM\SOFTWARE\Wow6432Node\JreMetrics" /va /f | Out-File -FilePath $Log -Append 2>NUL

        #Delete keys for for 32-bit and 64-bit Java installations on matching Windows architecture
        reg delete "HKLM\SOFTWARE\JavaSoft\Auto Update" /va /f | Out-File -FilePath $Log -Append 2>NUL
        reg delete "HKLM\SOFTWARE\JavaSoft\Java Plug-in" /va /f | Out-File -FilePath $Log -Append 2>NUL
        reg delete "HKLM\SOFTWARE\JavaSoft\Java Runtime Environment" /va /f | Out-File -FilePath $Log -Append 2>NUL
        reg delete "HKLM\SOFTWARE\JavaSoft\Java Update" /va /f | Out-File -FilePath $Log -Append 2>NUL
        reg delete "HKLM\SOFTWARE\JavaSoft\Java Web Start" /va /f | Out-File -FilePath $Log -Append 2>NUL
        reg delete "HKLM\SOFTWARE\JreMetrics" /va /f | Out-File -FilePath $Log -Append 2>NUL

        Write-Output ""
        Write-Output "$(Get-Date)   Keys purged." | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   Keys purged."
        Write-Output "$(Get-Date)   Registry cleanup done." | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   Registry cleanup done."
        Write-Output ""


        ##########::
        #FILE AND DIRECTORY CLEANUP ::
        ##########::
        :file_cleanup
        Write-Output "$(Get-Date)   Commencing file and directory cleanup..." | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   Commencing file and directory cleanup..."

        #Kill accursed Java tasks in Task Scheduler
        Write-Output "$(Get-Date)   Removing Java tasks from the Windows Task Scheduler..." | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   Removing Java tasks from the Windows Task Scheduler..."
        if exist $env:windir\tasks\Java*.job del /F /Q $env:windir\tasks\Java*.job | Out-File -FilePath $Log -Append
        if exist $env:windir\System32\tasks\Java*.job del /F /Q $env:windir\System32\tasks\Java*.job | Out-File -FilePath $Log -Append
        if exist $env:windir\SysWOW64\tasks\Java*.job del /F /Q $env:windir\SysWOW64\tasks\Java*.job | Out-File -FilePath $Log -Append
        Write-Output ""

        #Kill the accursed Java Quickstarter service
        sc query JavaQuickStarterService >NUL
        if not %ERRORLEVEL%==1060 (
	        Write-Output "$(Get-Date)   De-registering and removing Java Quickstarter service..." | Out-File -FilePath $Log -Append
	        Write-Output "$(Get-Date)   De-registering and removing Java Quickstarter service..."
	        net stop JavaQuickStarterService | Out-File -FilePath $Log -Append 2>NUL
	        sc delete JavaQuickStarterService | Out-File -FilePath $Log -Append 2>NUL
        )

        #Kill the accursed Java Update Scheduler service
        sc query jusched >NUL
        if not %ERRORLEVEL%==1060 (
	        Write-Output "$(Get-Date)   De-registering and removing Java Update Scheduler service..." | Out-File -FilePath $Log -Append
	        Write-Output "$(Get-Date)   De-registering and removing Java Update Scheduler service..."
	        net stop jusched | Out-File -FilePath $Log -Append 2>NUL
	        sc delete jusched | Out-File -FilePath $Log -Append 2>NUL
        )

        #This is the Oracle method of disabling the Java services. 99% of the time these commands aren't required. 
        if exist "${env:ProgramFiles(x86)}\Java\jre6\bin\jqs.exe" "${env:ProgramFiles(x86)}\Java\jre6\bin\jqs.exe" -disable | Out-File -FilePath $Log -Append
        if exist "${env:ProgramFiles(x86)}\Java\jre7\bin\jqs.exe" "${env:ProgramFiles(x86)}\Java\jre7\bin\jqs.exe" -disable | Out-File -FilePath $Log -Append
        if exist "$env:ProgramFiles\Java\jre6\bin\jqs.exe" "$env:ProgramFiles\Java\jre6\bin\jqs.exe" -disable | Out-File -FilePath $Log -Append
        if exist "$env:ProgramFiles\Java\jre7\bin\jqs.exe" "$env:ProgramFiles\Java\jre7\bin\jqs.exe" -disable | Out-File -FilePath $Log -Append
        if exist "${env:ProgramFiles(x86)}\Java\jre6\bin\jqs.exe" "${env:ProgramFiles(x86)}\Java\jre6\bin\jqs.exe" -unregister | Out-File -FilePath $Log -Append
        if exist "${env:ProgramFiles(x86)}\Java\jre7\bin\jqs.exe" "${env:ProgramFiles(x86)}\Java\jre7\bin\jqs.exe" -unregister | Out-File -FilePath $Log -Append
        if exist "$env:ProgramFiles\Java\jre6\bin\jqs.exe" "$env:ProgramFiles\Java\jre6\bin\jqs.exe" -unregister | Out-File -FilePath $Log -Append
        if exist "$env:ProgramFiles\Java\jre7\bin\jqs.exe" "$env:ProgramFiles\Java\jre7\bin\jqs.exe" -unregister | Out-File -FilePath $Log -Append
        msiexec.exe /x {4A03706F-666A-4037-7777-5F2748764D10} /qn /norestart

        #Nuke 32-bit Java installation directories
        if exist "${env:ProgramFiles(x86)}" (
	        Write-Output "$(Get-Date)   Removing "${env:ProgramFiles(x86)}\Java\jre*" directories..." | Out-File -FilePath $Log -Append
	        Write-Output "$(Get-Date)   Removing "${env:ProgramFiles(x86)}\Java\jre*" directories..."
	        for /D /R "${env:ProgramFiles(x86)}\Java\" %%x in (j2re*) do if exist "%%x" rmdir /S /Q "%%x" | Out-File -FilePath $Log -Append
	        for /D /R "${env:ProgramFiles(x86)}\Java\" %%x in (jre*) do if exist "%%x" rmdir /S /Q "%%x" | Out-File -FilePath $Log -Append
	        if exist "${env:ProgramFiles(x86)}\JavaSoft\JRE" rmdir /S /Q "${env:ProgramFiles(x86)}\JavaSoft\JRE" | Out-File -FilePath $Log -Append
        )

        #Nuke 64-bit Java installation directories
        Write-Output "$(Get-Date)   Removing "$env:ProgramFiles\Java\jre*" directories..." | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   Removing "$env:ProgramFiles\Java\jre*" directories..."
        for /D /R "$env:ProgramFiles\Java\" %%x in (j2re*) do if exist "%%x" rmdir /S /Q "%%x" | Out-File -FilePath $Log -Append
        for /D /R "$env:ProgramFiles\Java\" %%x in (jre*) do if exist "%%x" rmdir /S /Q "%%x" | Out-File -FilePath $Log -Append
        if exist "$env:ProgramFiles\JavaSoft\JRE" rmdir /S /Q "$env:ProgramFiles\JavaSoft\JRE" | Out-File -FilePath $Log -Append

        #Nuke Java installer cache ( thanks to cannibalkitteh )
        Write-Output "$(Get-Date)   Purging Java installer cache..." | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   Purging Java installer cache..."
        #XP VERSION
        if %OS_VERSION%==XP (
            #Get list of users, put it in a file, then use it to iterate through each users profile, deleting the AU folder
            dir "$env:SystemDrive\Documents and Settings\" /B > $env:TEMP\userlist.txt
            for /f "tokens=* delims= " %%a in ($env:TEMP\userlist.txt) do (
		        if exist "$env:SystemDrive\Documents and Settings\%%a\AppData\LocalLow\Sun\Java\AU" rmdir /S /Q "$env:SystemDrive\Documents and Settings\%%a\AppData\LocalLow\Sun\Java\AU" 2>NUL
	        )
            for /D /R "$env:SystemDrive\Documents and Settings\" %%x in (jre*) do if exist "%%x" rmdir /S /Q "%%x" 2>NUL
        ) else (
	        #ALL OTHER VERSIONS OF WINDOWS
            #Get list of users, put it in a file, then use it to iterate through each users profile, deleting the AU folder
            dir $env:SystemDrive\Users /B > $env:TEMP\userlist.txt
            for /f "tokens=* delims= " %%a in ($env:TEMP\userlist.txt) do rmdir /S /Q "$env:SystemDrive\Users\%%a\AppData\LocalLow\Sun\Java\AU" 2>NUL
            #Get the other JRE directories
            for /D /R "$env:SystemDrive\Users" %%x in (jre*) do rmdir /S /Q "%%x" 2>NUL
            )

        #Miscellaneous stuff, sometimes left over by the installers
        Write-Output "$(Get-Date)   Searching for and purging other Java Runtime-related directories..." | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   Searching for and purging other Java Runtime-related directories..."
        del /F /Q "$env:SystemDrive\1033.mst " | Out-File -FilePath $Log -Append 2>NUL
        del /F /S /Q "$env:SystemDrive\J2SE Runtime Environment*" | Out-File -FilePath $Log -Append 2>NUL
        Write-Output ""

        Write-Output "$(Get-Date)   File and directory cleanup done." | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   File and directory cleanup done."
        Write-Output "" | Out-File -FilePath $Log -Append
        Write-Output ""


        ########:
        #JAVA REINSTALLATION #-- If we wanted to reinstall the JRE after cleanup, this is where it happens
        ########:
        #x64
        if $Reinstall==yes (
            Write-Output "$(Get-Date) ! Variable REINSTALL_JAVA_x64 was set to 'yes'. Now installing %JAVA_BINARY_x64%..." | Out-File -FilePath $Log -Append
            Write-Output "$(Get-Date) ! Variable REINSTALL_JAVA_x64 was set to 'yes'. Now installing %JAVA_BINARY_x64%..."
            "%JAVA_LOCATION_x64%\%JAVA_BINARY_x64%" %JAVA_ARGUMENTS_x64%
            java -version
            Write-Output "Done." | Out-File -FilePath $Log -Append
            )

        #x86
        if $Reinstall==yes (
            Write-Output "$(Get-Date) ! Variable REINSTALL_JAVA_x86 was set to 'yes'. Now installing %JAVA_BINARY_x86%..." | Out-File -FilePath $Log -Append
            Write-Output "$(Get-Date) ! Variable REINSTALL_JAVA_x86 was set to 'yes'. Now installing %JAVA_BINARY_x86%..."
            "%JAVA_LOCATION_x86%\%JAVA_BINARY_x86%" %JAVA_ARGUMENTS_x86%
            java -version
            Write-Output "Done." | Out-File -FilePath $Log -Append
            )

        #Done.
        Write-Output "$(Get-Date)   Registry hive backups: $env:TEMP\java_purge_registry_backup\" | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   Registry hive backups: $env:TEMP\java_purge_registry_backup\"
        Write-Output "$(Get-Date)   Log file: $Log" | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   Log file: $Log"
        Write-Output "$(Get-Date)   JAVA NUKER COMPLETE. Recommend rebooting and washing your hands." | Out-File -FilePath $Log -Append
        Write-Output "$(Get-Date)   JAVA NUKER COMPLETE. Recommend rebooting and washing your hands."

        #Return exit code to SCCM/PDQ Deploy/PSexec/etc
        exit %EXIT_CODE%

        
    }
    Process
    {
    }
    End
    {
    }
}