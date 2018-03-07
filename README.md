# shell_monitoring

The documentation for this project is planned to grow - for now, you
can take a look at various entries in my website - for example
 * https://elbosso.github.io/roadmap_i_alarmmonitoring.html#content
 * https://elbosso.github.io/bash_monitoring_alarmierung_sms.html#content
 * https://elbosso.github.io/bash_monitoring.html#content
 
## Overview
I do know that there are solutions like for example
Nagios out there - and probably many many others. I am also
aware that some people consider one or the other of those solutions to 
be some kind of standard.

However - i startet this project when i wanted to learn something about
shell programming in linux and when we had recurring IT
infrastructure issues in the company where i worked when this project started.
The issues sometimes broke our internet connection so that even
if we had put some standard monitoring in place - we would not
have been alarmed.

The idea was to get a system up and runnign in as little time as possible 
and for that system to produce signals for alarming IT staff without
needing the internet to communicate.

Therefore the idea was born to have a central script that runs 
repeatedly and checks for "key performance indicators" IT infrastructure-wise.
When it detects errors or failures, it should send out alarms with
minimal information about the kpi that triggered the failure.
When no errors or failures are detected - it should provide
the time and date of its last successful execution.

This is essentially what the main script run-parts.sh does. But
not all kpis are checked inside this script: It starts scripts (a little
like the good old System V init) that each probe exactly one KPI
and then collects their result.

### Variables of run-parts.sh

This script is controlled by 5 variables at the start of the script:

#### FAILONERROR

This option allows the system to lazily stop its execution after the
first error or failure detected if set to 1. If the user instead sets its
value to 0, all kpis are determined - regardless if one of them results
in an error or failure. 

#### SCRIPTDIR

The directory this variable points to holds the scripts for determining
the kpis. A relatively new addition to the possibilities of the system is
that the user can control how often one of those scripts has to result
in an error or failure before an actual alarm is raised:

To do so, the user creates a file with the same name as the script in question
in directory $SCRIPTDIR/leniency:
Suppose he creates a file $SCRIPTDIR/leniency/01mem.sh containing the value 3 - 
That would mean, that the execution of the script $SCRIPTDIR/01mem.sh
would have to result in three consecutive failures before sending out an alarm.

The possibilities and meanings of directories below $SCRIPTDIR are even greater still:
Imagine a company having a large IT staff: The probability is high then that ther are
some people who know about the storage systems, some who know more about the virtualization solutions and
so on. In case of an error or failure it would be good to alarm only people who
can actually do something to mitigate the situation and are actually knowledgeable 
enough to to so.

The system supports that: Directories below $SCRIPTDIR whose names start with "cg_"
follow the same layout as is described for $SCRIPTDIR - however: error messages resulting
from scripts inside such directories get the remainder of the directory name (without the leading "cg_")
prepended to their messages.

Thus, it is easy to send the alarms for particular error messages only to members
of the associated call group. For example: error messages from scripts in directory
 $SCRIPTDIR/cg_A would get a "A|" prepended.
 
Scripts for call groups are executed before the general scripts residing directly inside 
$SCRIPTDIR.

#### WORKINGDIR

This is the directory where all scripts found in $SCRIPTDIR are executed. If it
doesn not exist, it is created and at the end of the execution of run-parts.sh deleted again.
If it exists, it is not deleted when the execution of run-parts.sh ends.

#### RESULTFILE

This file holds all the messages about errors and failures detected during assessment
of the kpis. In case ther was no error or failure, the time and date of the last execution 
of run-parts.sh is written in it instead. 

#### USECMDLINE

This switch determines if the four variables above are honoured or if the configuration items
are to be gotten from the commandl line (only if this variable has the value 1).

If configuration is supposed to happen via command line parameters, their order is as follows:

 script_dir working_dir fail_on_error result_file

## The example scripts

### template

It exists as starting point for sensor scripts. It shows that it 
is good form to write the name of the sensor script to stderr
before actually doing anything

This script should never signal an error or failure because it 
checks the return code from the echo command and if this indicates an error,
it signals this to its caller by printing a short but descriptive 
error message to stdout and returns a returncode that is not 0.

### check_dhcp.sh

This script adds a virtual linkto an existing network
device and tries to get a DHCP address for it. The virtual link is then removed
it signals an error if it was unable to actually
get a DHCP address 
for the virtual link.

### check_url.sh

This script tries to access a URL via wet. Signals an error if
it was unable to actually make the conection.

### error1.sh

This script exists for testing purposes - it always fails

### error2.sh

This script exists for testing purposes - it always fails

### failed_sysctl.sh

This script counts failed systemd modules and raises 
an error if their count exceeds a certain threshold. The actual number
of failed modules is part of the error message

### fileage.sh

This script checks the modification time of a certain file.
The name of the file is part of the error message as well as the
maximum allowed age if this maximum age is violated.

### filedescriptor_count.sh

This script calculates the percentage of available
file descriptors and raises an error if this percentage falls 
below the specified threshold.

### io_load.sh

This script calculates the io load of the system and raises
an error if the value raises over a specified threshold.

### link.sh

currently under development

### load.sh

This script calculates the load of the system and raises
an error if the value raises over a specified threshold.

### lxc_container_running.sh

This script checks wether a particular LXC container is running
and raises an error if not. The name of the container is contained
in the error message.

### mem.sh

This script computes the amount of used memory - if
this value exceeds the specified threshold, an error is raised.

### opened_tcp_ports.sh

This script counts the currently opened TCP ports - if their number
exceeds a threshold, an error is raised.

### opened_udp_ports.sh

This script counts the currently opened UDP ports - if their number
exceeds a threshold, an error is raised.

### ping_address.sh

This script tries to ping an IPv4 address and raises an error if
it does not succeed.

### ping_name.sh

This script tries to ping a remote computer by name and raises an error if
it does not succeed.

### port_knocker.sh

This script checks wether the specified port is opened on
the specified host and raises an error if this is not
the case.

### processes.sh

This script counts the currently running processes - if their number
exceeds a threshold, an error is raised.

### syslog_today.sh 

This script checks all syslog messages from today for the 
specified regular expression - if it is found at least once, an error is raised.
