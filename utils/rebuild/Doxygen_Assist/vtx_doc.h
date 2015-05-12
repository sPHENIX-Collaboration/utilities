/** 
 * @file  doxygen_mainpage.h
 * @brief This is not actually a header file but contains a doxygen "\mainpage" section.
 */
/** \page VTX VTX Offline Software
<!-- ================================================================ -->

This documentation explains the structure of the Svx Offline Code.
It is strongly recommended that when you modify the code 
you yourself update or add a comment in the code as well.

<hr> <!-- ================================================================ -->
<h2>Notations and Conventions</h2>
<ul>
  <li>As the PHENIX coding rule,
      a class name like "SvxFoov1" means it is implementation class
      and a corresponding class "SvxFoo" is abstract class.
  <li>A fired (stri)pixel is called "rawhit".
      A reconstructed hit is called "cluster"
      since it is a group of fired (stri)pixels.
  <li>For a set of abstract and implementation classes,
      the explanation of member functions is expected to be found in the abstract class.
</ul>

<hr> <!-- ================================================================ -->
<h2>Reconstruction Flow</h2>
SvxSimreco is a SubsysReco module and thus is registered in the Fun4AllServer.
It does
<ol>
  <li>read GEANT hits stored in simulated DST, 
  <li>simulate detector response (fired pixels and stripixels),
  <li>reconstruct the position etc. of each hit, and
  <li>write out lists of hits to an output ROOT file.
</ol>

Regarding 1.  It is done solely by SvxSimreco::fillGhitList().

Regarding 2.  
It is done in SvxSimreco::fillRawhitList().
The actual algorithm is in SvxStripixel::makeRawhits().

Regarding 3.
It is done in SvxSimreco::fillClusterList().
The actual algorithm is in SvxPixel1v1::findClusters() and
SvxStrip11v1::findClusters().

<hr> <!-- ================================================================ -->
<h2>Hit and Hit-Relator Class</h2>
One GEANT hit, rawhit and cluster
is represented by the class SvxGhit, SvxRawhit and SvxCluster, respectively.
The relation between GEANT hits and rawhits, for example,
(namely which GEANT hit is the parent of which rawhit)
is held by the class SvxGhitRawhit.
Each class has a corresponding list (or, say, container) class 
(for example, SvxGhit -&gt; SvxGhitList),
and all the list classes (or only what you selected) are written out
to an output ROOT file by SvxSimreco.
Please refer to the explanation of each class to know
what variable and how you can set/get.

<hr> <!-- ================================================================ -->
<h2>Detector Geometry</h2>
One pixel and stripixel sensor is represented by
the class SvxPixel1v1 and SvxStrip11v1, respectively.
SvxSimreco holds instances (SvxSimreco::barSensor) of the classes
and use them in making rawhits and clustering.
Some parameters and functionalities common to pixel and stripixel sensors
are implemented in the SvxStripixel class.
More deeply, a part of them is implemented in the SvxPixStruct class, and
SvxStripixel holds and uses an instance (SvxStripixel::senSec) of this class.
Actual values of sensor demensions can be found in SvxStripixel.C and SvxPixStruct.C.

The arrangement of detectors (namely the number and the position of ladders)
is read from the database via SvxSimreco::FetchBarrelPar() or
from your parameter file <tt>svxPISA.par</tt> 
via SvxSimreco::Read_svxPISApar().

<hr> <!-- ================================================================ -->
<h2>Tracking Algorithm</h2>
??

<!-- ================================================================ -->
 */
