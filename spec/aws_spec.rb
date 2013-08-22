# Copyright 2011-2013 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You
# may not use this file except in compliance with the License. A copy of
# the License is located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
# ANY KIND, either express or implied. See the License for the specific
# language governing permissions and limitations under the License.

require 'spec_helper'
require 'thread'

describe Ideeli::AWS do

  context '#config' do

    it 'should return a configuration object' do
      Ideeli::AWS.config.should be_a(Ideeli::AWS::Core::Configuration)
    end

    it 'should pass options through to Configuration#with' do
      previous = Ideeli::AWS.config
      previous.should_receive(:with).with(:access_key_id => "FOO")
      Ideeli::AWS.config(:access_key_id => "FOO")
    end

    it 'should return the same config when no options are added' do
      Ideeli::AWS.config.should be(Ideeli::AWS.config)
    end

  end

  context '#stub!' do

    it 'should set the config :stub_clients to true' do
      Ideeli::AWS.should_receive(:config).with(:stub_requests => true)
      Ideeli::AWS.stub!
    end

  end

  context '#start_memoizing' do

    after(:each) { Ideeli::AWS.stop_memoizing }

    it 'should enable memoization' do
      Ideeli::AWS.start_memoizing
      Ideeli::AWS.memoizing?.should be_true
    end

    it 'should return nil' do
      Ideeli::AWS.start_memoizing.should be_nil
    end

    it 'should not extend into other threads' do
      Ideeli::AWS.start_memoizing
      Thread.new do
        Ideeli::AWS.memoizing?.should be_false
      end.join
    end

  end

  context '#stop_memoizing' do

    it 'should do nothing if memoization is disabled' do
      Ideeli::AWS.memoizing?.should be_false
      Ideeli::AWS.stop_memoizing
      Ideeli::AWS.memoizing?.should be_false
    end

    it 'should stop memoization' do
      Ideeli::AWS.start_memoizing
      Ideeli::AWS.memoizing?.should be_true
      Ideeli::AWS.stop_memoizing
      Ideeli::AWS.memoizing?.should be_false
    end

    it 'should only affect the current thread' do
      Ideeli::AWS.start_memoizing
      t = Thread.new do
        Ideeli::AWS.start_memoizing
        Thread.stop
        Ideeli::AWS.memoizing?.should be_true
      end
      Thread.pass until t.stop?
      Ideeli::AWS.stop_memoizing
      t.wakeup
      t.join
    end

  end

  context '#memoize' do

    before(:each) do
      Ideeli::AWS.stub(:start_memoizing)
      Ideeli::AWS.stub(:stop_memoizing)
    end

    it 'should call start_memoization' do
      Ideeli::AWS.should_receive(:start_memoizing)
      Ideeli::AWS.memoize { }
    end

    it 'should call stop_memoization at the end of the block' do
      Ideeli::AWS.memoize do
        Ideeli::AWS.should_receive(:stop_memoizing)
      end
    end

    it 'should call stop_memoization for an exceptional exit' do
      Ideeli::AWS.memoize do
        Ideeli::AWS.should_receive(:stop_memoizing)
        raise "FOO"
      end rescue nil
    end

    it 'should return the return value of the block' do
      Ideeli::AWS.memoize { "foo" }.should == "foo"
    end

    context 'while already memoizing' do

      it 'should do nothing' do
        Ideeli::AWS.stub(:memoizing?).and_return(true)
        Ideeli::AWS.should_not_receive(:start_memoizing)
        Ideeli::AWS.should_not_receive(:stop_memoizing)
        Ideeli::AWS.memoize { }
      end

    end

  end

  shared_examples_for "memoization cache" do

    context 'memoizing' do

      before(:each) { Ideeli::AWS.start_memoizing }
      after(:each) { Ideeli::AWS.stop_memoizing }

      it 'should return a resource cache object' do
        Ideeli::AWS.send(method).should be_a(cache_class)
      end

      it 'should return a different cache each time memoization is enabled' do
        cache = Ideeli::AWS.send(method)
        Ideeli::AWS.stop_memoizing
        Ideeli::AWS.start_memoizing
        Ideeli::AWS.send(method).should_not be(cache)
      end

      it 'should return a different cache in each thread' do
        cache = Ideeli::AWS.send(method)
        Thread.new do
          Ideeli::AWS.memoize { Ideeli::AWS.send(method).should_not be(cache) }
        end.join
      end

    end

    context 'not memoizing' do

      it 'should return nil' do
        Ideeli::AWS.send(method).should be_nil
      end

    end

  end

  context '#resource_cache' do
    let(:method) { :resource_cache }
    let(:cache_class) { Ideeli::AWS::Core::ResourceCache }
    it_should_behave_like "memoization cache"
  end

  context '#response_cache' do
    let(:method) { :response_cache }
    let(:cache_class) { Ideeli::AWS::Core::ResponseCache }
    it_should_behave_like "memoization cache"
  end

  context '#config' do

    context "SERVICE_region" do

      it 'returns REGION when endpoint is SERVICE.REGION.amazonaws.com' do
        Ideeli::AWS.config.stub(:ec2_endpoint).and_return('ec2.REGION.amazonaws.com')
        Ideeli::AWS.config.ec2_region.should == 'REGION'
      end

      it 'returns us-east-1 when endpoint is SERVCIE.amazonaws.com' do
        Ideeli::AWS.config.stub(:ec2_endpoint).and_return('ec2.amazonaws.com')
        Ideeli::AWS.config.ec2_region.should == 'us-east-1'
      end

      it 'returns us-gov-west-1 when endpoint is ec2.us-gov-west-1.amazonaws.com' do
        Ideeli::AWS.config.stub(:ec2_endpoint).and_return('ec2.us-gov-west-1.amazonaws.com')
        Ideeli::AWS.config.ec2_region.should == 'us-gov-west-1'
      end

      it 'returns us-gov-west-2 when endpoint is s3-fips-us-gov-west-1.amazonaws.com' do
        Ideeli::AWS.config.stub(:s3_endpoint).and_return('s3-fips-us-gov-west-2.amazonaws.com')
        Ideeli::AWS.config.s3_region.should == 'us-gov-west-2'
      end

      it 'returns us-gov-west-1 when endpoint is iam.us-gov.amazonaws.com' do
        Ideeli::AWS.config.stub(:iam_endpoint).and_return('iam.us-gov.amazonaws.com')
        Ideeli::AWS.config.iam_region.should == 'us-gov-west-1'
      end

    end

  end

  context '#eager_autoload!' do

    it 'returns a list of loaded modules' do
      path = File.join(File.dirname(__FILE__), 'fixtures', 'autoload_target')
      mod = Module.new
      mod.send(:autoload, :AutoloadTarget, path)
      Ideeli::AWS.eager_autoload!(mod)
      mod.autoload?(:AutoloadTarget).should be(nil)
    end

    it 'eager autoloads passed defined modules' do
      path = File.join(File.dirname(__FILE__), 'fixtures', 'nested_autoload_target')
      mod = Module.new
      mod::Nested = Module.new
      mod::Nested.send(:autoload, :NestedAutoloadTarget, path)
      Ideeli::AWS.eager_autoload!(mod)
      mod::Nested.autoload?(:NestedAutoloadTarget).should be(nil)
    end

  end

end
