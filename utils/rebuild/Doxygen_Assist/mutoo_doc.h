/*! 

\page MuonArm Muon Arm Analysis

\tableofcontents

\section intro Introduction 
	
MUTOO is the current software used for all muon analysis starting from Run4
Au+Au data. It replaces the <i>old</i> MUT software used for the previous
data taling periods. The design goal of MUTOO is to provide well defined and
complete interfaces at each stage of the MUON tracker analysis and the
re-implementation   of standard MUT analysis modules in terms of these
interfaces. The incorporation of standard OO technology that mitigates  known
problems with table style data interfaces and equally  well known problems
with poorly designed object interfaces  is also a stated goal. 
   
\section tutorials Tutorials

Following tutorials illustrate the way we can run the muon software in the new Fun4All framework, for different configurations. If you are starting from scratch (i.e. an empty working direcotory), you have to proceed with the first tutorial (getting started) before any other. It will configure your directory for all other tutorials. 
  
<ul>
<li><a href="https://www.phenix.bnl.gov/WWW/muon/software/mutoo/html/group__TUTO.html">Getting started</a><br>
How to configure your workarea to use any of the tutorials below. </li>

<li><a href="https://www.phenix.bnl.gov/WWW/muon/software/mutoo/html/group__TUT1.html">Fun4Muons_RecoPRDF</a> tutorial<br>
How to generate a reconstructed DST, a nanoDST and a picoDST from a PRDF </li>

<li><a href="https://www.phenix.bnl.gov/WWW/muon/software/mutoo/html/group__TUT2.html">Fun4Muons_Pisa</a> tutorial<br> 
How to generate DST format Monte-Carlo data  (so-called slowsim DST) from PISA output</li>

<li><a href="https://www.phenix.bnl.gov/WWW/muon/software/mutoo/html/group__TUT3.html">Fun4Muons_RecoDST_sim</a> tutorial <br>
How to run the embedding, reconstruction, and evaluation software from a slowsim DST </li>

<li><a href="https://www.phenix.bnl.gov/WWW/muon/software/mutoo/html/group__TUT4.html">Fun4Muons_ReadDST</a> tutorial<br>
How to read back a reconstructed DST to generate a nanoDST a picoDST and evaluation ntuples</li>

<li><a href="https://www.phenix.bnl.gov/WWW/muon/software/mutoo/html/group__TUT5.html">Fun4Muons_Display</a> tutorial<br>
How to run mutoo 2D/3D event display on reconstructed DST.

<li><a href="https://www.phenix.bnl.gov/WWW/muon/software/mutoo/html/group__BUILD.html">Build instructions</a><br>
How to get a local build of the muon software.

<li><i>Running PYTHIA/PISA</i><br>
This tutorial, not directly related to the muon software, jas been moved elsewhere on the <i>pythia_muons</i> documentation page. It instructs how to generate a PISA file from scratch, usable as an input to the a <a href="https://www.phenix.bnl.gov/WWW/muon/software/mutoo/html/group__TUT2.html">Fun4Muons_Pisa</a> tutorial

</ul>

In principle each tutorial can be run independantly (provided you ran the first one once), since default files are provided during the setup stage. However, you may want to run them in a raw starting from a single PISA file, for a simulation or a PRDF for real data. Here are the two full chains:
<ul>
<li> starting from a (real data) PRDF file, you need to setup the directories, reconstruct the PRDF, possibly readback the reconstructed DST or run the event display. For this you need to run the
<ul>
<li><a href="https://www.phenix.bnl.gov/WWW/muon/software/mutoo/html/group__TUTO.html">Getting started</a> tutorial 
<li><a href="https://www.phenix.bnl.gov/WWW/muon/software/mutoo/html/group__TUT1.html">Fun4Muons_RecoPRDF</a> tutorial
<li> and possibly the <a href="group__TUT4.html">Fun4Muons_ReadDST</a> and/or <a href="group__TUT5.html">Fun4Muons_Display</a> tutorials
</ul><br>

<li> starting from a (simulated) pisa file, you need to setup the directories, generate the slowsim DST, reconstruct the DST, possibly readback the reconstructed DST or run the event display. For this you need to run the
<ul>
<li><a href="https://www.phenix.bnl.gov/WWW/muon/software/mutoo/html/group__TUTO.html">Getting started</a> tutorial 
<li><a href="https://www.phenix.bnl.gov/WWW/muon/software/mutoo/html/group__TUT2.html">Fun4Muons_Pisa</a> tutorial
<li><a href="https://www.phenix.bnl.gov/WWW/muon/software/mutoo/html/group__TUT3.html">Fun4Muons_RecoDST_sim</a> tutorial
<li> and possibly the <a href="https://www.phenix.bnl.gov/WWW/muon/software/mutoo/html/group__TUT4.html">Fun4Muons_ReadDST</a> and/or <a href="https://www.phenix.bnl.gov/WWW/muon/software/mutoo/html/group__TUT5.html">Fun4Muons_Display</a> tutorials
</ul>
</ul>

  \section touble_tutorials Troubles with tutorial 
  The turorials listed above are in the process of being made up to date. There may still be some temporarely inconsistancies and obselete things in these tutorials. If you are experiencing troubles, please send <a href="mailto:hpereira@hep.saclay.cea.fr">me</a> an email pointing to your macro, the file you are running it on and possibly the logfile, and I'll try to figure out the problem. Some error messages from new framework are sometime written to the stderr output and not the stdout, so that you'd better use 

\code root -b -q MyMacro.C >& run_log
\endcode

instead of 
\code root -b -q MyMacro.C > run_log
\endcode 

to redirect your macro output.

  \section BUILD Download and Build the Code  
  The <a href="https://www.phenix.bnl.gov/WWW/muon/software/mutoo/html/group__BUILD.html">Download Build and Run Instructions</a> are
  available now.<br>

  \section FAQ Frequently Asked Questions

  The <a href="https://www.phenix.bnl.gov/WWW/muon/software/mutoo/html/group__FAQ.html">MUTOO FAQ</a> is online<br>

  \section interface Interface Objects

  <a href="https://www.phenix.bnl.gov/WWW/muon/software/mutoo/html/group__interface.html">Interface Objects</a>
  provide data communication between analysis modules. The motivation for 
  defining such objects is to facilitate modularity in the analysis thus
  enabling different developers to simultaneously contribute to the project 
  as a whole.

  \section container Containers

  <a href="https://www.phenix.bnl.gov/WWW/muon/software/mutoo/html/group__container.html">Interface Objects Containers</a>
  manage collections of interface objects.  The general idea is that these 
  classes provide safe access to interface objects and an easy way to get
  at subsets of Interface Objects associated with a given portion of the 
  detector.

  \section modules Analysis Modules

  <a href="https://www.phenix.bnl.gov/WWW/muon/software/mutoo/html/group__modules.html">Analysis Modules</a> execute a specific task
  in the analysis software framework.  Analysis Modules have an Analysis Module 
  Interface (AMI) specification that describes what Interface Object Containers
  (IOCs) a module interacts with and with what privilege. 

  \section classes Class Library 

  The <a href="https://www.phenix.bnl.gov/WWW/muon/software/mutoo/html/group__classes.html">Class Library</a> contains 
  classes with MUTR specific utility as well as more general 
  utility classes.  Non detector specific classes are prefixed with a
  PH, Muon tracker specific classes are prefixed with a TMut. 

  <!-- 
  \section analysis DST Analysis
  <a href="https://www.phenix.bnl.gov/WWW/muon/software/mutoo/html/group__analysis.html">Analysis</a> Under Construction
  -->
  
  \section display Event Display

  <a href="https://www.phenix.bnl.gov/WWW/muon/software/mutoo/html/group__display.html">Event Display</a> contains classes
  for managing the interface between MUTOO and the PHENIX standard event
  display.  Included are classes for drawing the MUTR detector from various
  perspectives and representing the various stages of reconstruction.

  \section test Test Programs
  <a href="https://www.phenix.bnl.gov/WWW/muon/software/mutoo/html/group__test.html">Test Programs</a> are small stand alone routines 
  that demonstrate usage semantics or test a specific piece of library 
  functionality.


*/
