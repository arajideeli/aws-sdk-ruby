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

module Ideeli
module AWS
  class Glacier

    # All operations with Amazon Glacier require your AWS account ID.
    # You can specify the special value of '-' to specify your
    # AWS account ID.
    #
    #   glacier = Ideeli::AWS::Glacier.new
    #   resp = glacier.client.list_vaults(:account_id => '-')
    #
    class Client < Core::RESTJSONClient

      API_VERSION = '2012-06-01'

      # @api private
      CACHEABLE_REQUESTS = Set[]

      private

      def build_request *args
        request = super(*args)
        request.headers['x-amz-glacier-version'] = self.class.const_get(:API_VERSION)
        request
      end

    end

    class Client::V20120601 < Client

      define_client_methods('2012-06-01')

    end
  end
end
end
