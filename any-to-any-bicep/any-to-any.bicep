

var routeTables_all_to_firewall_we_name = 'all-to-firewall-we'
var routeTables_all_to_firewall_ne_name = 'all-to-firewall-ne'	
var ipGroups_all_spokes_subnets_name = 'all-spokes-subnets'


var hublabName = 'hub-lab-net'
var spoke01Name = 'spoke-01'
var spoke02Name = 'spoke-02'
var spoke03Name = 'spoke-03'

var firewallPolicyName = 'my-firewall-policy'
var firewallName = 'lab-firewall'

var locationWE = 'westeurope'
var locationNE = 'northeurope'

resource routeTableWE 'Microsoft.Network/routeTables@2020-05-01' = {
    name: routeTables_all_to_firewall_we_name
    location: locationWE
    properties: {
        disableBgpRoutePropagation: false
        routes: [
            {
                name: 'all-to-firewall-we'
                properties: {
                    addressPrefix: '0.0.0.0/0'
                    nextHopType: 'VirtualAppliance'
                    nextHopIpAddress: '10.12.3.4'
                }
            }
        ]
    }
}

resource routeTableNE 'Microsoft.Network/routeTables@2020-05-01' = {
    name: routeTables_all_to_firewall_ne_name
    location: locationNE
    properties: {
        disableBgpRoutePropagation: false
        routes: [
            {
                name: 'all-to-firewall-ne'
                properties: {
                    addressPrefix: '0.0.0.0/0'
                    nextHopType: 'VirtualAppliance'
                    nextHopIpAddress: '10.12.3.4'
                }
            }
        ]
    }
}

resource subnetS01default 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
    name: '${spoke01Name}/default'
    properties: {
        addressPrefix: '10.13.1.0/26'
        routeTable: {
            id: routeTableWE.id
        }
    }
}

resource subnetS01services 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
  name: '${spoke01Name}/services'
  properties: {
      addressPrefix: '10.13.1.64/26'
      routeTable: {
          id: routeTableWE.id
      }
  }
}

resource subnetS02default 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
  name: '${spoke02Name}/default'
  properties: {
      addressPrefix: '10.13.2.0/26'
      routeTable: {
          id: routeTableWE.id
      }
  }
}

resource subnetS02services 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
name: '${spoke02Name}/services'
properties: {
    addressPrefix: '10.13.2.64/26'
    routeTable: {
        id: routeTableWE.id
    }
}
}


resource subnetS03default 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
  name: '${spoke03Name}/default'
  properties: {
      addressPrefix: '10.13.3.0/26'
      routeTable: {
          id: routeTableNE.id
      }
  }
}

resource subnetS03services 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
name: '${spoke03Name}/services'
properties: {
    addressPrefix: '10.13.3.64/26'
    routeTable: {
        id: routeTableNE.id
    }
}
}

resource ipGroup 'Microsoft.Network/ipGroups@2020-05-01' = {
    name: ipGroups_all_spokes_subnets_name
    location: locationWE
    properties: {
        ipAddresses: [
            '10.13.1.0/24'
            '10.13.2.0/24'
            '10.13.3.0/24'
        ]
    }
}

resource myFirewallPolicy 'Microsoft.Network/firewallPolicies@2020-05-01' = {
    name: firewallPolicyName
    location: locationWE
    properties: {
        threatIntelMode: 'Alert'
        sku: {
            tier: 'Premium'
        }
      }
}



resource toInternetCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2020-05-01' = {
    parent: myFirewallPolicy
    name: 'DefaultApplicationRuleCollectionGroup'
    dependsOn: [
    ]
    properties: {
        priority: 200
        ruleCollections: [
            {
                ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
                name: 'internet-out-collection'
                priority: 1000
                action: { type: 'Allow' }
                rules: [
                  {
                    ruleType: 'ApplicationRule'
                    name: 'allow-internet-traffic-out'
                    protocols: [ { protocolType: 'Http', port: 80 }, { protocolType: 'Https', port: 443 } ]
                    targetFqdns: [  '*' ]
                    sourceIpGroups: [ ipGroup.id ]
                  }
                ]
            }
            {
                ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
                action: { type: 'Deny' }
                rules: [
                  {
                    ruleType: 'ApplicationRule'
                    name: 'block-xxx'
                    protocols: [ { protocolType: 'Http', port: 80 }, { protocolType: 'Https', port: 443 } ]
                    webCategories: [ 'Nudity', 'PornographyAndSexuallyExplicit' ]
                    sourceIpGroups: [ ipGroup.id ]
                  }
                  {
                    ruleType: 'ApplicationRule'
                    name: 'block-facebook'
                    protocols: [ { protocolType: 'Http', port: 80 }, { protocolType: 'Https', port: 443 } ]
                    targetFqdns: [ '*.facebook.com', 'facebook.com' ]
                    sourceIpGroups: [ ipGroup.id  ]
                  }
                  {
                    ruleType: 'ApplicationRule'
                    name: 'block-twitter'
                    protocols: [ { protocolType: 'Http', port: 80 }, { protocolType: 'Https', port: 443 } ]
                    targetFqdns: [ '*.twitter.com', 'twitter.com' ]
                    sourceIpGroups: [ ipGroup.id ]
                  }
                ]
                name: 'block-some-stuff'
                priority: 900
              }
        ]
    }
}

resource anyToAnyCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2020-05-01' = {
    parent: myFirewallPolicy
    name: 'DefaultNetworkRuleCollectionGroup'
    properties: {
        priority: 300
        ruleCollections: [
            {
                ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
                name: 'any-to-any-collection'
                priority: 1000
                action: {
                    type: 'Allow'
                }
                rules: [
                  {
                    ruleType: 'NetworkRule'
                    name: 'allow-spoke-to-spoke-traffic'
                    ipProtocols: [ 'Any' ]
                    sourceIpGroups: [
                      ipGroup.id                      
                    ]
                    destinationPorts: [
                      '*'
                    ]
                    destinationIpGroups: [
                      ipGroup.id                      
                    ]
                  }
                ]
            }
        ]
    }
}

resource azureFirewalls_lab_firewall_name_resource 'Microsoft.Network/azureFirewalls@2022-07-01' = {
    name: firewallName
    location: locationWE
    properties: {
      sku: {
        name: 'AZFW_VNet'
        tier: 'Premium'
      }
      
      networkRuleCollections: []
      applicationRuleCollections: []
      natRuleCollections: []
      firewallPolicy: {
        id: myFirewallPolicy.id
      }
    }
  }
