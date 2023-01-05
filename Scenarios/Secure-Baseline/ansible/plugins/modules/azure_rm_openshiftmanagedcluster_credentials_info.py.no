#!/usr/bin/python
#
# Copyright (c) 2020  haiyuazhang <haiyzhan@micosoft.com>
#
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type


DOCUMENTATION = '''
---
module: azure_rm_openshiftmanagedcluster_credentials_info
version_added: '1.12.0'
short_description: Get admin credentials of Azure Red Hat OpenShift Managed Cluster
description:
    - get credentials of Azure Red Hat OpenShift Managed Cluster instance.
options:
    resource_group:
        description:
            - The name of the resource group.
        required: true
        type: str
    name:
        description:
            - Resource name.
        required: true
        type: str
extends_documentation_fragment:
    - azure.azcollection.azure
    - azure.azcollection.azure_tags
author:
    - Paul Czarkowski (@paulczar)
'''

EXAMPLES = '''
    - name: List all Azure Red Hat OpenShift Managed Clusters for a given subscription
    azure_rm_openshiftmanagedcluster_info:
    - name: List all Azure Red Hat OpenShift Managed Clusters for a given resource group
    azure_rm_openshiftmanagedcluster_info:
        resource_group: myResourceGroup
    - name: Get Azure Red Hat OpenShift Managed Clusters
    azure_rm_openshiftmanagedcluster_info:
        resource_group: myResourceGroup
        name: myAzureFirewall
'''

RETURN = '''
kubeadminPassword:
    description:
        - kubeadmin password
    returned: always
    type: str
    sample: p4ssw0rd
name:
    kubeadminUsername:
        - kubeadmin username.
    returned: always
    type: str
    sample: kubeadmin
'''

import time
import json
import random
from ansible_collections.azure.azcollection.plugins.module_utils.azure_rm_common_ext import AzureRMModuleBaseExt
from ansible_collections.azure.azcollection.plugins.module_utils.azure_rm_common_rest import GenericRestClient
try:
    from msrestazure.azure_exceptions import CloudError
except ImportError:
    # this is handled in azure_rm_common
    pass


class Actions:
    NoAction, Create, Update, Delete = range(4)

class AzureRMOpenShiftManagedClustersCredentialsInfo(AzureRMModuleBaseExt):
    def __init__(self):
        self.module_arg_spec = dict(
            resource_group=dict(
                type='str', required=True
            ),
            name=dict(
                type='str', required=True
            )
        )

        self.resource_group = None
        self.name = None

        self.results = dict(changed=False)
        self.mgmt_client = None
        self.state = None
        self.url = None
        self.status_code = [200]

        self.query_parameters = {}
        self.query_parameters['api-version'] = '2020-04-30'
        self.header_parameters = {}
        self.header_parameters['Content-Type'] = 'application/json; charset=utf-8'

        self.mgmt_client = None
        super(AzureRMOpenShiftManagedClustersCredentialsInfo, self).__init__(self.module_arg_spec, supports_check_mode=True, supports_tags=False)

    def exec_module(self, **kwargs):

        for key in self.module_arg_spec:
            setattr(self, key, kwargs[key])

        self.mgmt_client = self.get_mgmt_svc_client(GenericRestClient,
                                                    base_url=self._cloud_environment.endpoints.resource_manager)
        self.results['credentials'] = self.list()
        return self.results

    def list(self):
        response = None
        results = {}
        # prepare url
        self.url = ('/subscriptions' +
                    '/{{ subscription_id }}' +
                    '/resourceGroups' +
                    '/{{ resource_group }}' +
                    '/providers' +
                    '/Microsoft.RedHatOpenShift' +
                    '/openshiftClusters' +
                    '/{{ cluster_name }}' +
                    '/listCredentials')
        self.url = self.url.replace('{{ subscription_id }}', self.subscription_id)
        self.url = self.url.replace('{{ resource_group }}', self.resource_group)
        self.url = self.url.replace('{{ cluster_name }}', self.name)
        try:
            response = self.mgmt_client.query(self.url,
                                              'POST',
                                              self.query_parameters,
                                              self.header_parameters,
                                              None,
                                              self.status_code,
                                              600,
                                              30)
            results = json.loads(response.text)
            # self.log('Response : {0}'.format(response))
        except CloudError as e:
            self.log('Could not get info for @(Model.ModuleOperationNameUpper).')
        return self.format_item(results)
        # return [self.url,self.query_parameters,self.header_parameters]
        # return [self.format_item(x) for x in results['value']] if results['value'] else []


    def format_item(self, item):
        d = {
            'kubeadminUsername': item['kubeadminUsername'],
            'kubeadminPassword': item['kubeadminPassword'],
        }
        return d


def main():
    AzureRMOpenShiftManagedClustersCredentialsInfo()


if __name__ == '__main__':
    main()
