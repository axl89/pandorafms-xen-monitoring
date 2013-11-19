pandorafms-xen-monitoring
=========================

Agent plugin for monitoring XEN virtual environments using Pandora FMS monitoring software.

``pandorafms-xen-monitoring`` is an agent plugin  for Pandora FMS (http://pandorafms.com) monitoring solution.

What does it monitor
--------------------

XEN-based virtualized environments.

It monitors the following:
- Domain-0:
  - CPU usage
  - Memory usage
  - Status
  - RX / TX Network metrics
  - Read / Write disk metrics
- Every VM inside XEN:
  - CPU usage
  - Memory usage
  - Status
  - RX / TX Network metrics
  - Read / Write disk metrics
  - Status
  - Number of virtual CPU's assigned

Where has been tested
---------------------

Using Xen version 4.2.2 under CentOS release 6.4 (Final)

Requisites
----------

For successfully executing this agent plugin (http://wiki.pandorafms.com/index.php?title=Pandora:Documentation_en:Operations#Using_software_agent_plugins) we will need:
- xentop v1.0
- Virsh command line tool of libvirt 1.0.3. See web site at http://libvirt.org/
- xm - Obsolete xen management user interface
- Pandora's Software Agent installed in the XEN's server (download and install it for your specific platform at sourceforge (http://sourceforge.net/projects/pandora/files/Pandora%20FMS%205.0/FinalSP1/).

