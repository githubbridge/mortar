#
# Copyright 2012 Mortar Data Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'spec_helper'
require 'fakefs/spec_helpers'
require 'mortar/command/jobs'
require 'mortar/api/jobs'

module Mortar::Command
  describe Jobs do
    
    before(:each) do
      stub_core      
      @git = Mortar::Git::Git.new
    end
        
    context("index") do
      it "shows help when user adds help argument" do
        with_git_initialized_project do |p|
          stderr_dash_h, stdout_dash_h = execute("jobs -h", p, @git) 
          stderr_help, stdout_help = execute("jobs help", p, @git)
          stdout_dash_h.should == stdout_help
          stderr_dash_h.should == stderr_help
        end
      end
    end
    
    context("run") do
      it "handles singlejobcluster parameter" do
        with_git_initialized_project do |p|
          # stub api requests
          job_id = "c571a8c7f76a4fd4a67c103d753e2dd5"
          job_url = "http://127.0.0.1:5000/jobs/job_detail?job_id=c571a8c7f76a4fd4a67c103d753e2dd5"
          cluster_size = 5

          mock(Mortar::Auth.api).post_job_new_cluster("myproject", "my_script", is_a(String), cluster_size, 
            :parameters => match_array([{"name" => "FIRST_PARAM", "value" => "FOO"}, {"name" => "SECOND_PARAM", "value" => "BAR"}]), 
            :keepalive => false,
            :notify_on_job_finish => true) {Excon::Response.new(:body => {"job_id" => job_id, "web_job_url" => job_url})}

          write_file(File.join(p.pigscripts_path, "my_script.pig"))
          stderr, stdout = execute("jobs:run my_script -1 --clustersize 5 -p FIRST_PARAM=FOO -p SECOND_PARAM=BAR", p, @git)
          stdout.should == <<-STDOUT
Taking code snapshot... done
Sending code snapshot to Mortar... done
Requesting job execution... done
job_id: c571a8c7f76a4fd4a67c103d753e2dd5

Job status can be viewed on the web at:

 http://127.0.0.1:5000/jobs/job_detail?job_id=c571a8c7f76a4fd4a67c103d753e2dd5

Or by running:

  mortar jobs:status c571a8c7f76a4fd4a67c103d753e2dd5 --poll

STDOUT
        end
      end
      
      it "runs a job on a new cluster" do
        with_git_initialized_project do |p|
          # stub api requests
          job_id = "c571a8c7f76a4fd4a67c103d753e2dd5"
          job_url = "http://127.0.0.1:5000/jobs/job_detail?job_id=c571a8c7f76a4fd4a67c103d753e2dd5"
          cluster_size = 5

          mock(Mortar::Auth.api).post_job_new_cluster("myproject", "my_script", is_a(String), cluster_size, 
            :parameters => match_array([{"name" => "FIRST_PARAM", "value" => "FOO"}, {"name" => "SECOND_PARAM", "value" => "BAR"}]), 
            :keepalive => true,
            :notify_on_job_finish => true) {Excon::Response.new(:body => {"job_id" => job_id, "web_job_url" => job_url})}

          write_file(File.join(p.pigscripts_path, "my_script.pig"))
          stderr, stdout = execute("jobs:run my_script --clustersize 5 -p FIRST_PARAM=FOO -p SECOND_PARAM=BAR", p, @git)
          stdout.should == <<-STDOUT
Taking code snapshot... done
Sending code snapshot to Mortar... done
Requesting job execution... done
job_id: c571a8c7f76a4fd4a67c103d753e2dd5

Job status can be viewed on the web at:

 http://127.0.0.1:5000/jobs/job_detail?job_id=c571a8c7f76a4fd4a67c103d753e2dd5

Or by running:

  mortar jobs:status c571a8c7f76a4fd4a67c103d753e2dd5 --poll

STDOUT
        end
      end

      it "runs a job with no cluster defined" do
        with_git_initialized_project do |p|
          job_id = "c571a8c7f76a4fd4a67c103d753e2dd5"
          job_url = "http://127.0.0.1:5000/jobs/job_detail?job_id=c571a8c7f76a4fd4a67c103d753e2dd5"
          cluster_size = 2

          mock(Mortar::Auth.api).post_job_new_cluster("myproject", "my_script", is_a(String), cluster_size, 
            :parameters => [], 
            :keepalive => true,
            :notify_on_job_finish => true) {Excon::Response.new(:body => {"job_id" => job_id, "web_job_url" => job_url})}

          write_file(File.join(p.pigscripts_path, "my_script.pig"))
          stderr, stdout = execute("jobs:run my_script ", p, @git)
          stdout.should == <<-STDOUT
Defaulting to running job on new cluster of size 2
Taking code snapshot... done
Sending code snapshot to Mortar... done
Requesting job execution... done
job_id: c571a8c7f76a4fd4a67c103d753e2dd5

Job status can be viewed on the web at:

 http://127.0.0.1:5000/jobs/job_detail?job_id=c571a8c7f76a4fd4a67c103d753e2dd5

Or by running:

  mortar jobs:status c571a8c7f76a4fd4a67c103d753e2dd5 --poll

STDOUT

        end
      end

      it "runs a job on an existing cluster" do
        with_git_initialized_project do |p|
          # stub api requests
          job_id = "c571a8c7f76a4fd4a67c103d753e2dd5"
          job_url = "http://127.0.0.1:5000/jobs/job_detail?job_id=c571a8c7f76a4fd4a67c103d753e2dd5"
          cluster_id = "e2790e7e8c7d48e39157238d58191346"

          mock(Mortar::Auth.api).post_job_existing_cluster("myproject", "my_script", is_a(String), cluster_id, :parameters => [], :notify_on_job_finish => false) {Excon::Response.new(:body => {"job_id" => job_id, "web_job_url" => job_url})}

          write_file(File.join(p.pigscripts_path, "my_script.pig"))
          stderr, stdout = execute("jobs:run my_script --clusterid e2790e7e8c7d48e39157238d58191346 -d", p, @git)
          stdout.should == <<-STDOUT
Taking code snapshot... done
Sending code snapshot to Mortar... done
Requesting job execution... done
job_id: c571a8c7f76a4fd4a67c103d753e2dd5

Job status can be viewed on the web at:

 http://127.0.0.1:5000/jobs/job_detail?job_id=c571a8c7f76a4fd4a67c103d753e2dd5

Or by running:

  mortar jobs:status c571a8c7f76a4fd4a67c103d753e2dd5 --poll

STDOUT
        end
      end

      it "runs a job with parameter file" do
        with_git_initialized_project do |p|
          job_id = "c571a8c7f76a4fd4a67c103d753e2dd5"
          cluster_size = 5
          keepalive = true

          mock(Mortar::Auth.api).post_job_new_cluster("myproject", "my_script", is_a(String), cluster_size, 
            :parameters => match_array([{"name" => "FIRST", "value" => "FOO"}, {"name" => "SECOND", "value" => "BAR"}, {"name" => "THIRD", "value" => "BEAR\n"}]), 
            :keepalive => true,
            :notify_on_job_finish => true) {Excon::Response.new(:body => {"job_id" => job_id})}

          write_file(File.join(p.pigscripts_path, "my_script.pig"))

          parameters = <<PARAMS
FIRST=PIZZA
SECOND=LASAGNA

THIRD=BEAR
PARAMS

          write_file(File.join(p.root_path, "params.ini"), parameters)
          stderr, stdout = execute("jobs:run my_script --clustersize 5 -p FIRST=FOO -p SECOND=BAR --param-file params.ini", p, @git)
        end
      end

      it "runs a job with parameter file with comments" do
        with_git_initialized_project do |p|
          job_id = "c571a8c7f76a4fd4a67c103d753e2dd5"
          cluster_size = 5
          keepalive = true

          mock(Mortar::Auth.api).post_job_new_cluster("myproject", "my_script", is_a(String), cluster_size, 
            :parameters => match_array([{"name" => "FIRST", "value" => "FOO"}, {"name" => "SECOND", "value" => "BAR"}, {"name" => "THIRD", "value" => "BEAR\n"}]), 
            :keepalive => true,
            :notify_on_job_finish => true) {Excon::Response.new(:body => {"job_id" => job_id})}

          write_file(File.join(p.pigscripts_path, "my_script.pig"))

          parameters = <<PARAMS
FIRST=PIZZA
SECOND=LASAGNA
; This is a test

THIRD=BEAR
PARAMS

          write_file(File.join(p.root_path, "params.ini"), parameters)
          stderr, stdout = execute("jobs:run my_script --clustersize 5 -p FIRST=FOO -p SECOND=BAR --param-file params.ini", p, @git)
        end
      end

      it "runs a job with malformed parameter file" do
        with_git_initialized_project do |p|
          job_id = "c571a8c7f76a4fd4a67c103d753e2dd5"
          cluster_size = 5
          keepalive = true

          write_file(File.join(p.pigscripts_path, "my_script.pig"))

          parameters = <<PARAMS
FIRST=PIZZA
SECONDLASAGasNA
; This is a test
Natta
THIRD=BEAR
PARAMS

          write_file(File.join(p.root_path, "params.ini"), parameters)
          stderr, stdout = execute("jobs:run my_script --clustersize 5 -p FIRST=FOO -p SECOND=BAR --param-file params.ini", p, @git)
          stderr.should == <<-STDERR
 !    Parameter file is malformed
STDERR
        end
      end
    end
    
    context("status") do
      
      it "gets status for a completed, successful job" do
        with_git_initialized_project do |p|
          job_id = "c571a8c7f76a4fd4a67c103d753e2dd5"
          pigscript_name = "my_script"
          project_name = "myproject"
          status_code = Mortar::API::Jobs::STATUS_SUCCESS
          progress = 100
          outputs = [{'name'=> 'hottest_songs_of_the_decade', 
                      'records' => 10, 
                      'alias' => 'output_data',
                      'location' => 's3n://my-bucket/my-folder/hottest_songs_of_the_decade/output_data'},
                     {'name'=> 'hottest_songs_of_the_decade', 
                      'records' => 100,
                      'alias' => 'output_data_2',
                      'location' => 's3n://my-bucket/my-folder/hottest_songs_of_the_decade/output_data_2'}]
          cluster_id = "e2790e7e8c7d48e39157238d58191346"
          start_timestamp = "2012-02-28T03:35:42.831000+00:00"
          running_timestamp = "2012-02-28T03:41:52.613000+00:00"
          stop_timestamp = "2012-02-28T03:44:52.613000+00:00"
          parameters = {"my_param_1" => "value1", "MY_PARAM_2" => "3"}

          mock(Mortar::Auth.api).get_job(job_id) {Excon::Response.new(:body => {"job_id" => job_id,
            "pigscript_name" => pigscript_name,
            "project_name" => project_name,
            "status_code" => status_code,
            "status_description" => "Success",
            "progress" => progress,
            "cluster_id" => cluster_id,
            "start_timestamp" => start_timestamp,
            "running_timestamp" => running_timestamp,
            "stop_timestamp" => stop_timestamp,
            "duration" => "6 mins",
            "num_hadoop_jobs" => 4,
            "num_hadoop_jobs_succeeded" => 4,
            "parameters" => parameters,
            "outputs" => outputs
            })}
          stderr, stdout = execute("jobs:status c571a8c7f76a4fd4a67c103d753e2dd5", p, @git)
          stdout.should == <<-STDOUT
=== myproject: my_script (job_id: c571a8c7f76a4fd4a67c103d753e2dd5)
cluster_id:              e2790e7e8c7d48e39157238d58191346
hadoop jobs complete:    4.00 / 4.00
job began running at:    2012-02-28T03:41:52.613000+00:00
job finished at:         2012-02-28T03:44:52.613000+00:00
job run with parameters: 
  MY_PARAM_2:   3
  my_param_1:   value1
job running for:         6 mins
job submitted at:        2012-02-28T03:35:42.831000+00:00
outputs:                 
  output_data:   
    location:     s3n://my-bucket/my-folder/hottest_songs_of_the_decade/output_data
    records:      10
  output_data_2: 
    location:     s3n://my-bucket/my-folder/hottest_songs_of_the_decade/output_data_2
    records:      100
progress:                100%
status:                  Success
STDOUT
        end
      end
          
      it "gets status for a running job" do
        with_git_initialized_project do |p|
          job_id = "c571a8c7f76a4fd4a67c103d753e2dd5"
          pigscript_name = "my_script"
          project_name = "myproject"
          status_code = Mortar::API::Jobs::STATUS_RUNNING
          progress = 55
          cluster_id = "e2790e7e8c7d48e39157238d58191346"
          start_timestamp = "2012-02-28T03:35:42.831000+00:00"
          running_timestamp = "2012-02-28T03:41:52.613000+00:00"
          parameters = {"my_param_1" => "value1", "MY_PARAM_2" => "3"}
          
          mock(Mortar::Auth.api).get_job(job_id) {Excon::Response.new(:body => {"job_id" => job_id,
            "pigscript_name" => pigscript_name,
            "project_name" => project_name,
            "status_code" => status_code,
            "status_description" => "Running",
            "progress" => progress,
            "cluster_id" => cluster_id,
            "start_timestamp" => start_timestamp,
            "running_timestamp" => running_timestamp,
            "duration" => "6 mins",
            "num_hadoop_jobs" => 4,
            "num_hadoop_jobs_succeeded" => 2,
            "parameters" => parameters
            })}
          stderr, stdout = execute("jobs:status c571a8c7f76a4fd4a67c103d753e2dd5", p, @git)
          stdout.should == <<-STDOUT
=== myproject: my_script (job_id: c571a8c7f76a4fd4a67c103d753e2dd5)
cluster_id:              e2790e7e8c7d48e39157238d58191346
hadoop jobs complete:    2.00 / 4.00
job began running at:    2012-02-28T03:41:52.613000+00:00
job run with parameters: 
  MY_PARAM_2:   3
  my_param_1:   value1
job running for:         6 mins
job submitted at:        2012-02-28T03:35:42.831000+00:00
progress:                55%
status:                  Running
STDOUT
        end
      end

      it "gets status for a error job" do
        with_git_initialized_project do |p|
          job_id = "c571a8c7f76a4fd4a67c103d753e2dd5"
          pigscript_name = "my_script"
          project_name = "myproject"
          status_code = Mortar::API::Jobs::STATUS_EXECUTION_ERROR
          progress = 55
          cluster_id = "e2790e7e8c7d48e39157238d58191346"
          start_timestamp = "2012-02-28T03:35:42.831000+00:00"
          running_timestamp = "2012-02-28T03:41:52.613000+00:00"
          stop_timestamp = "2012-02-28T03:45:52.613000+00:00"
          parameters = {"my_param_1" => "value1", "MY_PARAM_2" => "3"}
          error = {"message" => "An error occurred and here's some more info",
                   "type" => "RuntimeError",
                   "line_number" => 43,
                   "column_number" => 34}
          mock(Mortar::Auth.api).get_job(job_id) {Excon::Response.new(:body => {"job_id" => job_id,
            "pigscript_name" => pigscript_name,
            "project_name" => project_name,
            "status_code" => status_code,
            "status_description" => "Execution error",
            "progress" => progress,
            "cluster_id" => cluster_id,
            "start_timestamp" => start_timestamp,
            "running_timestamp" => running_timestamp,
            "stop_timestamp" => stop_timestamp,
            "duration" => "6 mins",
            "num_hadoop_jobs" => 4,
            "num_hadoop_jobs_succeeded" => 0,
            "parameters" => parameters,
            "error" => error
            })}
          stderr, stdout = execute("jobs:status c571a8c7f76a4fd4a67c103d753e2dd5", p, @git)
          stdout.should == <<-STDOUT
=== myproject: my_script (job_id: c571a8c7f76a4fd4a67c103d753e2dd5)
cluster_id:              e2790e7e8c7d48e39157238d58191346
error - column_number:   34
error - line_number:     43
error - message:         An error occurred and here's some more info
error - type:            RuntimeError
hadoop jobs complete:    0.00 / 4.00
job began running at:    2012-02-28T03:41:52.613000+00:00
job finished at:         2012-02-28T03:45:52.613000+00:00
job run with parameters: 
  MY_PARAM_2:   3
  my_param_1:   value1
job running for:         6 mins
job submitted at:        2012-02-28T03:35:42.831000+00:00
progress:                55%
status:                  Execution error
STDOUT
        end
      end
      it "gets status for a running job using polling" do
        with_git_initialized_project do |p|
          job_id = "c571a8c7f76a4fd4a67c103d753e2dd5"
          pigscript_name = "my_script"
          project_name = "myproject"
          status_code = Mortar::API::Jobs::STATUS_RUNNING
          progress = 0
          cluster_id = "e2790e7e8c7d48e39157238d58191346"
          start_timestamp = "2012-02-28T03:35:42.831000+00:00"
          stop_timestamp = "2012-02-28T03:44:52.613000+00:00"
          running_timestamp = "2012-02-28T03:41:52.613000+00:00"
          parameters = {"my_param_1" => "value1", "MY_PARAM_2" => "3"}

          mock(Mortar::Auth.api).get_job(job_id).returns(Excon::Response.new(:body => {"job_id" => job_id,
            "pigscript_name" => pigscript_name,
            "project_name" => project_name,
            "status_code" => status_code,
            "status_description" => "Execution error",
            "progress" => progress,
            "cluster_id" => cluster_id,
            "start_timestamp" => start_timestamp,
            "running_timestamp" => running_timestamp,
            "duration" => "6 mins",
            "num_hadoop_jobs" => 4,
            "num_hadoop_jobs_succeeded" => 0,
            "parameters" => parameters
            }))

          status_code = Mortar::API::Jobs::STATUS_SUCCESS
          progress = 100
          outputs = [{'name'=> 'hottest_songs_of_the_decade', 
                      'records' => 10, 
                      'alias' => 'output_data',
                      'location' => 's3n://my-bucket/my-folder/hottest_songs_of_the_decade/output_data'},
                     {'name'=> 'hottest_songs_of_the_decade', 
                      'records' => 100,
                      'alias' => 'output_data_2',
                      'location' => 's3n://my-bucket/my-folder/hottest_songs_of_the_decade/output_data_2'}]

          mock(Mortar::Auth.api).get_job(job_id).returns(Excon::Response.new(:body => {"job_id" => job_id,
            "pigscript_name" => pigscript_name,
            "project_name" => project_name,
            "status_code" => status_code,
            "status_description" => "Success",
            "progress" => progress,
            "cluster_id" => cluster_id,
            "start_timestamp" => start_timestamp,
            "running_timestamp" => running_timestamp,
            "stop_timestamp" => stop_timestamp,
            "duration" => "6 mins",
            "num_hadoop_jobs" => 4,
            "num_hadoop_jobs_succeeded" => 4,
            "parameters" => parameters,
            "outputs" => outputs
            }))
          stderr, stdout = execute("jobs:status c571a8c7f76a4fd4a67c103d753e2dd5 -p --polling_interval 0.05", p, @git)
          stdout.should == <<-STDOUT
\r[/] Status: [=>                    ] 0% Complete (0.00 / 4.00 MapReduce jobs finished)\r\e[0K=== myproject: my_script (job_id: c571a8c7f76a4fd4a67c103d753e2dd5)
cluster_id:              e2790e7e8c7d48e39157238d58191346
hadoop jobs complete:    4.00 / 4.00
job began running at:    2012-02-28T03:41:52.613000+00:00
job finished at:         2012-02-28T03:44:52.613000+00:00
job run with parameters: 
  MY_PARAM_2:   3
  my_param_1:   value1
job running for:         6 mins
job submitted at:        2012-02-28T03:35:42.831000+00:00
outputs:                 
  output_data:   
    location:     s3n://my-bucket/my-folder/hottest_songs_of_the_decade/output_data
    records:      10
  output_data_2: 
    location:     s3n://my-bucket/my-folder/hottest_songs_of_the_decade/output_data_2
    records:      100
progress:                100%
status:                  Success
STDOUT
        end
      end

      context("stop") do
        it "Stops a running job with default message" do
          job_id = "1234abcd"
          mock(Mortar::Auth.api).stop_job(job_id) {Excon::Response.new(:body => {"success" => true})}

          stderr, stdout = execute("jobs:stop #{job_id}")
          stdout.should == <<-STDOUT
Stopping job #{job_id}.
STDOUT
        end

        it "Stops a running job with server message" do
          job_id = "1234abcd"
          message = "some awesome message"
          mock(Mortar::Auth.api).stop_job(job_id) {Excon::Response.new(:body => {"success" => true, "message" => message})}

          stderr, stdout = execute("jobs:stop #{job_id}")
          stdout.should == "#{message}\n"
        end


      end
    end
  end
end
