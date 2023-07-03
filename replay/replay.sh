#!/bin/bash

/usr/bin/inotifywait -m --format '%f' -e close_write /pcap/ /evtx/ | while read FILE
do
    if [[ "$FILE" == *".pcap" ]]; then
        docker exec suricata sh -c "suricata --runmode=autofp -c /etc/suricata/suricata.yaml -l /var/log/suricata -r /pcap/$FILE";
        docker exec zeek sh -c "zeek -C local -r /pcap/$FILE";
        rm -fr /pcap/$FILE;
    elif [[ "$FILE" == *".evtx" ]]; then
        docker run --rm --name zircolite --network instance_name_s1em -v instance_name_zircolite:/case/ docker.io/wagga40/zircolite:latest --ruleset rules/rules_windows_sysmon_full.json --evtx /case/ --outfile /case/detected_events.json --remote 'https://es01:9200' --index 'zircolite-whatever' --eslogin "${ZIRCOLITE_USER}" --espass "${ZIRCOLITE_PASSWORD}" --forwardall --remove-events --nolog;
    fi
done;