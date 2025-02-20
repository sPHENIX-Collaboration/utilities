pipeline 
{
	agent any
    
//    environment { 
//        JenkinsBase = 'jenkins/test/'
//    }
    options {
        timeout(time: 8, unit: 'HOURS') 
    }
       
	stages { 
	
		stage('Checkrun update') 
		{
		
			steps {
				build(job: 'github-commit-checkrun',
				parameters:
				[
					string(name: 'checkrun_repo_commit', value: "${checkrun_repo_commit}"), 
					string(name: 'src_Job_id', value: "${env.JOB_NAME}/${env.BUILD_NUMBER}"),
					string(name: 'src_details_url', value: "${env.BUILD_URL}"),
					string(name: 'checkrun_status', value: "in_progress")
				],
				wait: false, propagate: false)
			} // steps
		} // stage('Checkrun update') 
		
		stage('Prebuild-Cleanup') 
		{
			steps {
				timestamps {
					ansiColor('xterm') {
					
						script {
							currentBuild.displayName = "${env.BUILD_NUMBER} - ${system_config} - ${build_type} - ${macro_full_path}"
							currentBuild.description = """\
${upstream_build_description} - ${system_config} - ${build_type}\
${macro_full_path}(${function_parameters})"""
							
						
							if (fileExists('./install'))
							{
								sh "rm -fv ./install"
							}
							if (fileExists('./calibrations'))
							{
								sh "rm -fv ./calibrations"
							}						
							if (fileExists('./build'))
							{
								sh "rm -fv ./build"
							}	
							
							sh('rm -fv *.*')					
						}						
    				
						echo("link builds to ${build_src}")
						sh('ln -svfb ${build_src}/install ./install')
						sh('ln -svfb ${build_src}/calibrations ./calibrations')

						dir('macros')
						{
							deleteDir()
						}	

						dir('coresoftware') {
							deleteDir()
						}

						dir('report')
						{
							deleteDir()
    					}
						sh('ls -lvhc')
					}
				}
			}
		}
	
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
							
							sh("$singularity_exec_sphenix_farm  tcsh -f singularity-check.sh ${build_type}")
						
						}
					}
				}
			}
		}

		stage('Git Checkout')
		{
			
			steps 
			{
				timestamps { 
					ansiColor('xterm') {
						
						dir('macros')
						{					
							
							checkout(
								[
						 			$class: 'GitSCM',
						   		extensions: [               
							   		[$class: 'CleanCheckout'],     
							     	[
							   			$class: 'PreBuildMerge',
							    		options: [
											mergeRemote: 'origin',
							  			mergeTarget: 'master'
							  			]
							    	],
						   		],
							  	branches: [
							    	[name: "${sha_macros}"]
							    ], 
							  	userRemoteConfigs: 
							  	[[
							     	credentialsId: 'sPHENIX-bot', 
							     	url: '${git_url_macros}',
							     	refspec: ('+refs/pull/*:refs/remotes/origin/pr/* +refs/heads/master:refs/remotes/origin/master'), 
							    	branch: ('*')
							  	]]
								] //checkout
							)//checkout
							
    				}	
    				
						
					}
				}
			}
		}//stage('SCM Checkout')
		
		stage('Test')
		{
			steps 
			{					
				dir('macros') {
					sh("$singularity_exec_sphenix_farm sh ../utilities/jenkins/built-test/test-default-generic.sh ${macro_full_path} '${function_parameters}' ${run_valgrind}")
				}	
				
				archiveArtifacts artifacts: 'macros/detectors/sPHENIX/*prdf_reconstruction*.root*'			
									
			}				
					
		}

		stage('valgrind_report')
		{
			when {
				// case insensitive regular expression for truthy values
				expression { return params.run_valgrind == "1" }
			}
			steps 
			{			
				archiveArtifacts artifacts: "macros/${macro_full_path}.valgrind*"
				
				publishValgrind (
				  failBuildOnInvalidReports: true,
				  failBuildOnMissingReports: true,
				  failThresholdDefinitelyLost: '1',
				  failThresholdInvalidReadWrite: '0',
				  failThresholdTotal: '1000',
				  pattern: "macros/${macro_full_path}.valgrind.xml",
				  publishResultsForAbortedBuilds: false,
				  publishResultsForFailedBuilds: false,
				  sourceSubstitutionPaths: '',
				  unstableThresholdDefinitelyLost: '0',
				  unstableThresholdInvalidReadWrite: '0',
				  unstableThresholdTotal: '300'
				)			
			}		
		}
		
		stage('PerformanceAnalysis')
		{
			steps 
			{
					
				sh("${python_bin} utilities/jenkins/built-test/test-output-parser.py --input_file macros/${macro_full_path}.log --output_csv test-default-generic.csv")
				
				plot( csvFileName: 'test-default-generic.csv_Time_(s)_Summary.csv', 
					csvSeries: 
					[[
						exclusionValues: 'Time (s)', 
						file: 'test-default-generic.csv_Time_(s).csv', 
						inclusionFlag: 'INCLUDE_BY_STRING', 
						url: "${env.JOB_URL}" + '/%build%/'
					]], 
					description: 'User time (s), from system time tool', 
					exclZero: true, 
					group: 'Analysis', 
					numBuilds: '40', 
					style: 'line',
					title: 'User time (s)',
					yaxis: 'Time (s)'			
				)
				plot( csvFileName: 'test-default-generic.csv_Memory_(kB)_Summary.csv', 
					csvSeries: 
					[[
						exclusionValues: 'Memory (kB)', 
						file: 'test-default-generic.csv_Memory_(kB).csv', 
						inclusionFlag: 'INCLUDE_BY_STRING', 
						url: "${env.JOB_URL}" + '/%build%/'
					]], 
					description: 'Maximum resident set size (kbytes), from system time tool', 
					exclZero: true, 
					group: 'Analysis', 
					numBuilds: '40', 
					style: 'line',
					title: 'Maximum resident memory',
					yaxis: 'Memory (kB)'			
				)
				plot( csvFileName: 'test-default-generic.csv_STDOUT_Linecount_Summary.csv', 
					csvSeries: 
					[[
						exclusionValues: 'STDOUT Linecount', 
						file: 'test-default-generic.csv_STDOUT_Linecount.csv', 
						inclusionFlag: 'INCLUDE_BY_STRING', 
						url: "${env.JOB_URL}" + "/%build%/artifact/macros/${macro_full_path}.log"
					]], 
					description: 'line count of the text output', 
					exclZero: true, 
					group: 'Analysis', 
					numBuilds: '40', 
					style: 'line',
					title: 'Output line count',
					yaxis: 'Line count'			
				)
				plot( csvFileName: 'test-default-detector.csv_Module_per_event_time_(ms)_Summary.csv', 
					csvSeries: 
					[[
						file: 'test-default-generic.csv_Module_per_event_time_(ms).csv', 
						exclusionValues: '', 
						inclusionFlag: 'OFF', 
						url: "${env.JOB_URL}" + '/%build%/'
					]], 
					description: 'per-event time (ms) for each of the Fun4All modules', 
					exclZero: true, 
					group: 'Analysis', 
					numBuilds: '40', 
					style: 'line',
					title: 'per-event time (ms)',
					yaxis: 'time (ms)'			
				)
			}				
		}
	}//stages

	
	post {

		always{
		  
			
			script {

				build_result_description = "* [![Build Status](${env.JENKINS_URL}/buildStatus/icon?job=${env.JOB_NAME}&build=${env.BUILD_NUMBER})](${env.BUILD_URL}) system `${system_config}`, build `${build_type}`: run [the default ${macro_full_path} macro](https://github.com/sPHENIX-Collaboration/macros/tree/master/${macro_full_path}): [build is ${currentBuild.currentResult}](${env.BUILD_URL}), [output](${env.BUILD_URL}), [trends :bar_chart:](${env.JOB_URL}/plot/) "

				if (params.run_valgrind == "1")
				{
					build_result_description = "* [![Build Status](${env.JENKINS_URL}/buildStatus/icon?job=${env.JOB_NAME}&build=${env.BUILD_NUMBER})](${env.BUILD_URL}) system `${system_config}`, build `${build_type}`: Valgrind test of [${macro_full_path}](https://github.com/sPHENIX-Collaboration/macros/tree/master/${macro_full_path}): [build is ${currentBuild.currentResult}](${env.BUILD_URL}), [:bar_chart:valgrind report](${env.BUILD_URL}/valgrindResult/), [trends :bar_chart:](${env.JOB_URL}/plot/) "
				}						

				currentBuild.description = "${currentBuild.description}\n${build_result_description}"
			}					

			dir('report')
			{
			  writeFile file: "test-default-generic-${system_config}-${build_type}-valgrind${run_valgrind}-${macro_full_path}.md".replaceAll('/','_'), text: "${build_result_description}"
			}
		  		  
			archiveArtifacts artifacts: 'report/*.md'
						
			build(job: 'github-commit-checkrun',
				parameters:
				[
					string(name: 'checkrun_repo_commit', value: "${checkrun_repo_commit}"), 
					string(name: 'src_Job_id', value: "${env.JOB_NAME}/${env.BUILD_NUMBER}"),
					string(name: 'src_details_url', value: "${env.BUILD_URL}"),
					string(name: 'checkrun_status', value: "completed"),
					string(name: 'checkrun_conclusion', value: "${currentBuild.currentResult}"),
					string(name: 'output_title', value: "sPHENIX Jenkins Report for ${env.JOB_NAME}"),
					string(name: 'output_summary', value: "${build_result_description}" ),
					string(name: 'output_text', value: "${currentBuild.displayName}\n\n${currentBuild.description}")
				],
				wait: false, propagate: false
			) // build(job: 'github-commit-checkrun',
			
			archiveArtifacts artifacts: 'macros/**/*.log'
		}
	}
}//pipeline 
