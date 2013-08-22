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
  class ImportExport

    # Client class for AWS Import/Export.
    class Client < Core::QueryClient

      API_VERSION = '2010-06-01'

      # @api private
      CACHEABLE_REQUESTS = Set[]

    end

    class Client::V20100601 < Client

      define_client_methods('2010-06-01')

    end
  end
end
end
