#!/bin/bash
set -vo errexit

# generate filters and configs
./gen_peering_filters all

if [ ! -d filter-cache/rpki ]; then
    mkdir -p filter-cache/rpki
fi

rtrsub --afi ipv4 < ./templates/bird-rpki.j2 > filter-cache/rpki/rpki-ipv4.conf
rtrsub --afi ipv6 < ./templates/bird-rpki.j2 > filter-cache/rpki/rpki-ipv6.conf

for router in dcg-1.router.nl.coloclue.net dcg-2.router.nl.coloclue.net eunetworks-2.router.nl.coloclue.net; do
    rm -rf staged-configs/${router}
    mkdir -p staged-configs/${router}

    ./gentool -y vars/generic.yml -t templates/envvars.j2 -o staged-configs/${router}/envvars
    ./gentool -y vars/${router}.yml -t templates/header.j2 -o staged-configs/${router}/header.conf
    ./gentool -y vars/${router}.yml -t templates/interfaces.j2 -o staged-configs/${router}/interfaces.conf
    ./gentool -y vars/${router}.yml -t templates/generic_filters.j2 -o staged-configs/${router}/generic_filters.conf
    ./gentool -4 -y vars/generic.yml -t templates/afi_specific_filters.j2 -o staged-configs/${router}/ipv4_filters.conf
    ./gentool -6 -y vars/generic.yml -t templates/afi_specific_filters.j2 -o staged-configs/${router}/ipv6_filters.conf

    ./gentool -4 -y vars/${router}.yml vars/members_bgp.yml -t templates/members_bgp.j2 -o staged-configs/${router}/members_bgp-ipv4.conf
    ./gentool -6 -y vars/${router}.yml vars/members_bgp.yml -t templates/members_bgp.j2 -o staged-configs/${router}/members_bgp-ipv6.conf

    # DCG specific stuff
    if [ "${router}" == "dcg-1.router.nl.coloclue.net" ] || [ "${router}" == "dcg-2.router.nl.coloclue.net" ]; then
        ./gentool -4 -t templates/static_routes.j2 -y vars/statics-dcg.yml -o staged-configs/${router}/static_routes-ipv4.conf
        ./gentool -6 -t templates/static_routes.j2 -y vars/statics-dcg.yml -o staged-configs/${router}/static_routes-ipv6.conf
    # EUNetworks specific stuff
    elif [ "${router}" == "eunetworks-2.router.nl.coloclue.net" ]; then
        ./gentool -4 -t templates/static_routes.j2 -y vars/statics-eunetworks.yml -o staged-configs/${router}/static_routes-ipv4.conf
        ./gentool -6 -t templates/static_routes.j2 -y vars/statics-eunetworks.yml -o staged-configs/${router}/static_routes-ipv6.conf
    fi

    rsync -av blobs/${router}/ staged-configs/${router}/ 
    rsync -av filter-cache/rpki/ staged-configs/${router}/rpki/

    # dcg-2 does not have peering
    if [ "${router}" != "dcg-2.router.nl.coloclue.net" ]; then
        rsync -av filter-cache/*bird* staged-configs/${router}/peerings/
        rsync -av filter-cache/${router}.ipv4.config staged-configs/${router}/peerings/peers.ipv4.conf
        rsync -av filter-cache/${router}.ipv6.config staged-configs/${router}/peerings/peers.ipv6.conf
    fi
done

# sync config to routers
#eval $(ssh-agent -t 600)
#ssh-add /root/.ssh/id_rsa_dcg1

if [ "$1" == "push" ]; then

    for router in dcg-1.router.nl.coloclue.net dcg-2.router.nl.coloclue.net eunetworks-2.router.nl.coloclue.net; do
        echo checking and uploading for ${router} 
        bird -c staged-configs/${router}/bird.conf -p && 
        bird6 -c staged-configs/${router}/bird6.conf -p && 
        rsync -avH --delete staged-configs/${router}/ root@${router}:/etc/bird/
        ssh root@${router} '/usr/sbin/birdc configure; /usr/sbin/birdc6 configure' | sed "s/^/${router}: /"
    done

fi

if [ "$1" == "check" ]; then

    for router in dcg-1.router.nl.coloclue.net dcg-2.router.nl.coloclue.net eunetworks-2.router.nl.coloclue.net; do
        echo "checking: staged-configs/${router}/bird.conf"
        bird -c staged-configs/${router}/bird.conf -p
        echo "checking: staged-configs/${router}/bird6.conf"
        bird6 -c staged-configs/${router}/bird6.conf -p
    done
fi

# kill ssh-agent
#eval $(ssh-agent -k)
