pipeline 
{
	agent any
    
//    environment { 
//        JenkinsBase = 'jenkins/test/'
//    }
    options {
        timeout(time: 1, unit: 'HOURS') 
    }
       
	stages { 
	
	
		stage('Initialize') 
		{
			
            
			steps {
				timestamps {
					ansiColor('xterm') {
					
						sh('hostname')
						sh('pwd')
						sh('env')
						
						sh('ls -lvhc')
    				
						dir('utilities/jenkins/built-test/') {
							
							sh('$singularity_exec_sphenix  tcsh -f singularity-check.sh ${build_type}')
						
						}
						
					}
				}
			}
		}
 
		stage('Test CDB')
		{
			
			
			steps 
			{
					
				sh("$singularity_exec_sphenix_farm bash utilities/jenkins/built-test/test-cdb-readback.sh")
														
			}				
					
		}

        
	}//stages

	
	post {
		always{
			archiveArtifacts artifacts: '*.log'
		}
	}
}//pipeline 

