pipeline 
{
	agent any
    
//    environment { 
//        JenkinsBase = 'jenkins/test/'
//    }
       
	stages { 
			
		stage('Initialize') 
		{
			
            
			steps {
				timestamps {
					ansiColor('xterm') {
					
						sh("env");
						
						script{
							if ( "${ref_build_id}" == "" )
							{
								echo("Build failed because of ref_build_id is empty (${ref_build_id})");
								error("Build failed because of ref_build_id is empty")				
							}
						}
					
						echo("Build ${build_src} ref_build_id = (${ref_build_id})");
						
						deleteDir()						

					}
				}
			}
		}
		
		stage('test-calo-single-qa')
		{
			//input {
			//	message "Pick a reference build in ${test-calo-single-qa}?"
      //          parameters {
      //              string(name: 'ref_build_id', description: 'Reference build ID?')
      //          }
      //      }
					
			steps 
			{
				echo ("copyArtifacts(projectName: ${build_src}, selector: specific(${ref_build_id}))");
		   	copyArtifacts(projectName: "${build_src}", selector: specific("${ref_build_id}"));
		    //copyArtifacts(projectName: "${test-calo-single-qa}");
		   	
		   	dir('QA-gallery')
		   	{
		   		stash name: "test-calo-single-qa-stash", includes: "*"
		   	}
		   	
				deleteDir()		
		   			
		   	unstash "test-calo-single-qa-stash"
		   	archiveArtifacts artifacts: '*.*', onlyIfSuccessful: true	
		   	
			}				
		}//		stage('test-calo-single-qa')
		
		
	}
	
	post {

		success {
			script
			{
				currentBuild.displayName = "${env.BUILD_NUMBER} - ${build_src} / ${ref_build_id}"
				
				currentBuild.description = "Selected reference build ${ref_build_id} from ${build_src}"		         
			}
			
		}
	}
}//pipeline 

