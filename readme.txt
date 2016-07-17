--------------------------------------------------------------------------------
                                 AppKiller 3.x
--------------------------------------------------------------------------------



Index
----------------------------------------
Content of this document divided into individual parts, with line numbers at
which each part starts.

  Index ...................................................   7
  Description .............................................  26
  Project information .....................................  46
  Installation ............................................  60
  How to use the program ..................................  75
  Changelog ............................................... 117
  Known issues and limitations ............................ 126
  Licensing ............................................... 135
  Repositories ............................................ 154
  Authors, contacts ....................................... 166
  Copyright ............................................... 172



Description
----------------------------------------
This program is designed to help terminate unresponsive applications in Windows
operating system. Normally, a user would do it from task manager, but in certain
situations, task manager might not be accessible or visible (fullscreen
application cannot be minimized, task switching does not work, etc..), AppKiller
can be used in such situation - it reacts to predefined system-global shortcut
and starts terminating any program according to certain rules (see section
"How to use the program"). Therefore, as long as the actual operating system and
AppKiller itself both works, you can terminate unresponsive programs without
opening new window of any kind.

                             !!! A BIG WARNING !!!

AppKiller does not care what program is about to be terminated, if you happen to
kill important process or editor with unsaved document, it is only your fault.
Only you are responsible for your actions, so take great care configuring
AppKiller and be cautious while using its termination functions.
This program is generally recommended only for experienced users.



Project information
----------------------------------------
This project is primarily developed in Delphi 7 Personal and Lazarus 1.6
(FPC 3.0). It should be possible to compile it in higher versions of
Lazarus/FPC and possibly newer Delphi too, code is also compatible with older
versions of Lazarus, namely Laz 1.4+ (FPC 2.6.4).
Project is configured in a way that you should be able to compile it without any
preparations. It is also possible to compile it into both 32bit and 64bit
binaries.



Installation
----------------------------------------
Select proper build for your needs (any 32bit build for a 32bit system, 64bit
build for a 64bit system) and place the executable to any directory where you
have full access rights (program will write its configuration and log into the
same folder it is placed in).
Run the program - note that no window will appear, program runs only in the
background - it will add its icon into notification area, you can use this icon
to access the program and its settings.
The program also automatically adds itself between programs run at system
startup - if you don't want this feature, you can deactivate it in program's
settings.



How to use the program
----------------------------------------
Given the nature of this program, it has to run in the background the whole time
you want to use it. The program has minimal footprint (uses less than 1.5MiB of
memory and does almost nothing), so it is possible to let it run for indefinite
time. Just let it start automatically at the system startup and leave it running
in the background.
First thing you should do after installation is to fill list of processes to be
automatically terminated (processes you know are problematic) and list of
processes that should be never terminated (eg. system processes, hardware
managers, ...). Also note that in both lists, items that are not checked are
ignored.
You should also consider changing default shortcut that is used to start the
termination.

Description of termination methods (you can (de)activate any of them separately
in general settings):

  Terminate process of foreground window

    This function finds current foreground window and terminates process it is
    belonging to as long as it is not listed in the no-terminate list.
    Be very careful about this function, as it can end processes that are
    actually fully working or are not clearly in the foreground (small window
    on the screen edge, ...).

  Terminate processes from the list

    This method will enumerate all running processes within the system and then
    tries to terminate any of those that happen to be listed in the terminate
    list and in the same time not in the no-terminate list.
    It can be used to end processes that have no visible window or processes
    that are known to be problematic.

  Terminate unresponsive processes

    This function enumerates all windows in the system and then tries all of
    them whether they are responding within a selected timeout period. Those,
    that are not, are terminated (process they belongs to).



Changelog
----------------------------------------
List of changes between individual versions of this program.

AppKiller 2.x -> AppKiller 3.0.0
  - program rewritten from scratch



Known issues and limitations
----------------------------------------
If you run this program on Windows Vista or newer, you should be avare that it
does not have access to protected and system processes (generally any process
with higher privileges), and therefore cannot terminate them.
I will correct this only when there will be demand.



Licensing
----------------------------------------
Everything (source codes, executables/binaries, configurations, etc.), with few
exceptions mentioned below, is licensed under Mozilla Public License Version
2.0. You can find full text of this license in file mpl_license.txt or on web
page https://www.mozilla.org/MPL/2.0/.
Exception being following folders and their entire content:

./Documents

  This folder contains documents (texts, images, ...) used in creation of this
  program. Everything in this folder is licensed under the terms of Creative
  Commons Attribution-ShareAlike 4.0 (CC BY-SA 4.0) license. You can find full
  legal code in file CC_BY-SA_4.0.txt or on web page
  http://creativecommons.org/licenses/by-sa/4.0/legalcode. Short wersion is
  available on web page http://creativecommons.org/licenses/by-sa/4.0/.



Repositories
----------------------------------------
You can get actual copies of AppKiller on either of these git repositories:

https://github.com/ncs-sniper/AppKiller
https://bitbucket.org/ncs-sniper/appkiller

Note - Master branch does not contain binaries, they can be found in a branch
       called bin (this branch will not be updated as often as master branch).



Authors, contacts
----------------------------------------
František Milt, frantisek.milt@gmail.com



Copyright
----------------------------------------
©2010-2016 František Milt, all rights reserved