/*! \page FVTX FVTX Software Guide
 *
 * \tableofcontents
 *
 * \section intro_sec Introduction
 *
 * This website documents the software used for the <a href = "http://www.phenix.bnl.gov/WWW/fvtx/">Forward Vertex silicon detector</a>.
 * It is based on
 * <a href = "https://www.phenix.bnl.gov/WWW/offline/wikioff/index.php/Fun4All"> the same framework</a>
 *  as the rest of PHENIX software. The major software repository included on this site including
 *
 * \li <a href="files.html">offline/packages/fvtxgeom/</a>: FVTX Geometry base
 * \li <a href="files.html">offline/packages/fvtxoo/</a>: FVTX internal modules
 * \li <a href="files.html">offline/packages/fvtx_subsysreco/</a>: FVTX external modules
 * \li <a href="files.html">offline/packages/mutoo/</a>: MuTr internal modules
 * \li <a href="files.html">offline/packages/mutoo_subsysreco/</a>: MuTr external modules
 * \li <a href="files.html">offline/packages/mui*</a>: MuID modules
 * \li <a href="files.html">offline/packages/vtx/</a>: VTX modules
 * \li <a href="files.html">offline/packages/MWG</a>: Muon Arm nDST modules
 * \li <a href="files.html">offline/AnalysisTrain/picoDST_object/</a>: Muon Arm pDST modules
 * \li and the Fun4All framework.
 *
 * You are welcome to start by browsing the menu on the left. And the serch box on the right-top of this window is very useful too.
 * Each class is listed on <a href="./annotated.html">the Class List</a> and documented on
 * separated pages (e.g. \ref FvtxReco ). You can also start with
 * the <a href = "./files.html">directory list</a>.
 *
 * For the rest of PHENIX software or history of the code, please refer to the <a href = "http://www.phenix.bnl.gov/viewvc/viewvc.cgi/phenix/">PHENIX CVS pages</a>.
 *
 *
 * \section Data_flow Data Flow for FVTX Analysis
 *
 * Following is a interactive data flow chart for FVTX analysis.
 * It includes major FVTX-related classes which process (grey)
 * and store (white) data during each of the analysis stages.
 * Click on the boxes for documentation of the corresponding codes.
 *
 * Example script to run this analysis chain can be found at \ref Fun4FVTX_RecoPRDF.C .
 *
 * \dot

    digraph data_flow {

      node [shape=folder, fontname=Helvetica, fontsize=10];

      PRDF [ label="Raw Data (PRDF)" URL="https://www.phenix.bnl.gov/WWW/offline/wikioff/index.php/PRDF_Utilities"];
      nDST [ label="nano-DST"];
      pDST [ label="pico-DST"];
      PISA [ label="Simulation (Click for more)" URL="#Sim_flow"];
      FvtxMon [ label="Online Monitoring (FvtxMon)" URL="\ref FvtxMon"];
      Geometry [ label="Geometry Database" URL = "https://www.phenix.bnl.gov/WWW/offline/wikioff/index.php/FVTX/calibration_database#Geometry_Database"];
      DeadMap [ label="Dead map databases" URL = "https://www.phenix.bnl.gov/WWW/offline/wikioff/index.php/FVTX/QA"];


      node [shape=record, fontname=Helvetica, fontsize=10];

      TFvtxHit [ label="Strip hit (TFvtxHit)" URL="\ref TFvtxHit"];
      VTX [ label="VTX data (SvxClusterList)" URL="\ref SvxClusterList"];

      TFvtxClus [ label="FVTX cluster (TFvtxClus)" URL="\ref TFvtxClus"];
      TFvtxSvxCluster [ label="VTX cluster (TFvtxSvxCluster)" URL="\ref TFvtxSvxCluster"];
      TFvtxCoord [ label="Cluster position (TFvtxCoord)" URL="\ref TFvtxCoord"];
      TFvtxTrk [ label="FVTX track (TFvtxTrk)" URL="\ref TFvtxTrk"];
      TFvtxCompactTrk [ label="FVTX tracklet (TFvtxCompactTrk)" URL="\ref TFvtxCompactTrk"];
      TFvtxTrkF [ label="FVTX track w/ fit (TFvtxTrk)" URL="\ref TFvtxTrk"];

      TMutTrk [ label="Muon arm track (TMutTrk)" URL="\ref TMutTrk"];
      TFvtxTrkM [ label="FVTX track w/ MuTr Fit (TFvtxTrk)" URL="\ref TFvtxTrk"];
      TMutTrkF [ label="Muon track with \n link to FVTX track (TMutTrk)" URL="\ref TMutTrk"];
      PHMuoTracksOut [ label="Muon arm track (PHMuoTracksOut)" URL="\ref PHMuoTracksOut"];

      SingleMuonContainer [ label="Single Muon track (SingleMuonContainer)" URL="\ref SingleMuonContainer"];
      DiMuonContainer [ label="Di-Muon tracks (DiMuonContainer)" URL="\ref DiMuonContainer"];


      node [shape=ellipse, fontname=Helvetica, fontsize=10, style=filled, fillcolor=grey];

      FvtxGeom [ label="FvtxGeom" URL="\ref FvtxGeom"];

      mFvtxUnpack [ label="mFvtxUnpack" URL="\ref mFvtxUnpack"];
      mFvtxFindClus [ label="mFvtxFindClus" URL="\ref mFvtxFindClus"];
      mFvtxFindSvxClusters [ label="mFvtxFindSvxClusters" URL="\ref mFvtxFindSvxClusters"];
      mFvtxFindCoord [ label="mFvtxFindCoord" URL="\ref mFvtxFindCoord"];
      mFvtxFindTracks [ label="mFvtxFindTracks" URL="\ref mFvtxFindTracks"];
      mFvtxKalFit [ label="mFvtxKalFit" URL="\ref mFvtxKalFit"];
      mMutKalFitWithSiliReal [ label="mMutKalFitWithSiliReal" URL="\ref mMutKalFitWithSiliReal"];

      MWGFvtxReco [ label="MWGFvtxReco" URL="\ref MWGFvtxReco"];

      mFillSingleMuonContainer [ label="mFillSingleMuonContainer" URL="\ref mFillSingleMuonContainer"];
      mFillDiMuonContainer [ label="mFillDiMuonContainer" URL="\ref mFillDiMuonContainer"];

      TFvtxDeadMap [ label="TFvtxDeadMap" URL="\ref TFvtxDeadMap"];


      node [shape=note, fontname=Helvetica, fontsize=10, style=filled, fillcolor=yellow];
      Info [ label="Interactive chart for FVTX data flow\nby Jin Huang <jhuang@bnl.gov>" URL = "mailto:jhuang@bnl.gov"];

      Geometry -> FvtxGeom;

      FvtxGeom -> mFvtxFindCoord  [ arrowhead="open", style="dashed" ];
      FvtxGeom -> mFvtxFindTracks  [ arrowhead="open", style="dashed" ];
      DeadMap -> TFvtxDeadMap ;
      TFvtxDeadMap -> mFvtxFindClus [ arrowhead="open", style="dashed" ];

      PRDF -> mFvtxUnpack -> TFvtxHit [weight = 100];
      mFvtxUnpack -> FvtxMon;
      PISA -> TFvtxHit;

      TFvtxHit -> mFvtxFindClus -> TFvtxClus -> mFvtxFindCoord  [weight = 100];
      mFvtxFindCoord -> TFvtxCoord -> mFvtxFindTracks -> TFvtxTrk -> mFvtxKalFit -> TFvtxTrkF  [weight = 100];



      PRDF -> VTX [ arrowhead="empty", style="dotted", constraint=false ];
      VTX -> mFvtxFindSvxClusters -> TFvtxSvxCluster -> mFvtxFindTracks;


      TFvtxTrkF -> mMutKalFitWithSiliReal -> TFvtxTrkM -> MWGFvtxReco-> PHMuoTracksOut -> nDST  [weight = 100];
      TMutTrk -> mMutKalFitWithSiliReal;
      mMutKalFitWithSiliReal -> TMutTrkF;
      TMutTrkF -> MWGFvtxReco;

      mFvtxKalFit -> TFvtxCompactTrk;
      TFvtxCompactTrk -> nDST [constraint=false ];

      nDST -> mFillSingleMuonContainer -> SingleMuonContainer -> mFillDiMuonContainer -> DiMuonContainer  [weight = 100];
      SingleMuonContainer -> pDST;
      DiMuonContainer -> pDST  [weight = 100];
    }

 * \enddot
 *
 *
 * \section Sim_flow Data Flow for FVTX Simulation
 *
 * Following is a interactive flow chart for FVTX simulation,
 * which generates \ref TFvtxHit and connects to the above
 * \ref Data_flow "data flow chart".
 * Click on the boxes for documentation of the corresponding codes.
 *
 * Example script to run this analysis chain can be found at \ref Fun4Muons_Pisa.C .
 *
 * \dot

    digraph sim_flow {

      node [shape=folder, fontname=Helvetica, fontsize=10];

      PISA [ label="PHENIX Simulation (PISA)" URL="https://www.phenix.bnl.gov/WWW/offline/wikioff/index.php/Simulations"];

      PISA_Data [ label="PISA Data File (SvxPisaHit)" URL="\ref SvxPisaHit"];




      node [shape=record, fontname=Helvetica, fontsize=10];

      TFvtxPisaHit [ label="Copy of PISA data (TFvtxPisaHit)" URL="\ref TFvtxPisaHit"];
      TFvtxMCHit [ label="Simulated FVTX hit (TFvtxMCHit)" URL="\ref TFvtxMCHit"];
      TFvtxHit [ label="Strip hit (TFvtxHit)\nClick for main chart" URL="\ref Data_flow"];

      node [shape=ellipse, fontname=Helvetica, fontsize=10, style=filled, fillcolor=grey];

      PISA_FVTX [ label="F/VTX Digitalization (CVS/svx_digi.f)" URL="http://www.phenix.bnl.gov/viewvc/viewvc.cgi/phenix/simulation/pisa2000/src/svx/svx_digi.f?view=markup"];
      PISA_FVTX_EXPORT [ label="Export to RootFile (CVS/encodeRootEvntSvx.cc)" URL="http://www.phenix.bnl.gov/viewvc/viewvc.cgi/phenix/simulation/pisa2000/src/phnxcore/encodeRootEvntSvx.cc?view=markup"];


      mFvtxSlowSim [ label="mFvtxSlowSim" URL="\ref mFvtxSlowSim"];
      mFvtxResponse [ label="mFvtxResponse" URL="\ref mFvtxResponse"];

      node [shape=note, fontname=Helvetica, fontsize=10, style=filled, fillcolor=yellow];
      Info [ label="Interactive chart for FVTX simulation flow\nby Jin Huang <jhuang@bnl.gov>" URL = "mailto:jhuang@bnl.gov"];

      PISA -> PISA_FVTX -> PISA_FVTX_EXPORT -> PISA_Data  [weight = 100];
      PISA_Data ->  mFvtxSlowSim -> TFvtxMCHit -> mFvtxResponse -> TFvtxHit  [weight = 100];
      mFvtxSlowSim -> TFvtxPisaHit ;

    }

 * \enddot
 *
 *
 * */
























