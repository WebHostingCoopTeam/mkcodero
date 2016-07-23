
ls: lsServers

listServers: API_KEY
	$(eval API_KEY := $(shell cat API_KEY))
	curl -X GET "https://apis.codero.com/cloud/v1/servers" \
	-H "Authorization: $(API_KEY)" \
	-m 30 \
	-v > listServers

lsServers: listServers
	cat listServers|jq .

fullList: API_KEY  listServers
	jq -r '.data[] | "\(.id) \(.hostname)  \(.displayname) \(.details.osName) \(.details.osVer) \(.ip.public) \(.ip.servicenet) \(.ip.nat)"  ' listServers >> fullList

listJobs: API_KEY
	$(eval API_KEY := $(shell cat API_KEY))
	curl -X GET "https://apis.codero.com/cloud/v1/jobs/f56827eb-9bf1-4137-877b-b2495cab0cce" \
	-H "Authorization: $(API_KEY)" \
	-m 30 \
	-v > listJobs

jobsList: listJobs
	jq -r '.data[]  | " \(.job_id) \(.job_message) "' listJobs > jobsList

jobsDetails: API_KEY jobsList
	$(eval API_KEY := $(shell cat API_KEY))
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	echo  '#!/bin/bash' > $(TMP)/working.sh
	while read JID MESSAGE; \
		do \
		echo -n "curl -X GET 'https://apis.codero.com/cloud/v1/jobs/$$JID' " >> $(TMP)/working.sh ; \
		echo -n '-H "Authorization: $(API_KEY)" ' >> $(TMP)/working.sh ; \
		echo -n '-m 30 ' >> $(TMP)/working.sh ; \
		echo "-v > $(TMP)/jobby" >> $(TMP)/working.sh ; \
		done < jobsList
	@bash $(TMP)/working.sh
	cat $(TMP)/working.sh
	cat $(TMP)/jobby | jq .
	@rm -Rf $(TMP)

API_KEY:
	@while [ -z "$$API_KEY" ]; do \
		read -r -p "Enter the API KEY you wish to associate with this container [API_KEY]: " API_KEY; echo "$$API_KEY">>API_KEY; cat API_KEY; \
	done ;

resetpassworder:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval PWD := $(shell pwd))
	$(eval API_KEY := $(shell cat API_KEY))
	$(eval URL := https://apis.codero.com/cloud/v1/servers/)
	$(eval DATA :=key=$(API_KEY)&login=$(API_USERNAME)&action=reset)
	while read SID HOSTNAME NAME OSNAME OSVER IP SERVICENET NAT ; \
		do \
		echo -n "curl -X PUT $(URL)$$SID/reset_password " >> $(TMP)/working.sh ; \
		echo -n '-H "Authorization: $(API_KEY)" ' >> $(TMP)/working.sh ; \
		echo -n '-m 30 ' >> $(TMP)/working.sh ; \
		echo "-v > $(TMP)/jobby" >> $(TMP)/working.sh ; \
		done < workingList > $(TMP)/resetpassworder
	-/usr/bin/time parallel  --jobs 2 -- < $(TMP)/resetpassworder
	cat $(TMP)/jobby | jq .
	@rm -Rf $(TMP)

rebooter:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval API_KEY := $(shell cat API_KEY))
	$(eval URL := https://apis.codero.com/cloud/v1/servers/)
	$(eval DATA :=key=$(API_KEY)&login=$(API_USERNAME)&action=reset)
	while read SID HOSTNAME NAME IP ROOTPASSWORD ID; \
		do \
		echo -n "curl -X PUT $(URL)$$SID/reboot  " >> $(TMP)/working.sh ; \
		echo -n '-H "Authorization: $(API_KEY)" ' >> $(TMP)/working.sh ; \
		echo -n '-m 30 ' >> $(TMP)/working.sh ; \
		echo "-v > $(TMP)/jobby" >> $(TMP)/working.sh ; \
		done < workingList > $(TMP)/rebooter
	-/usr/bin/time parallel  --jobs 2 -- < $(TMP)/rebooter
	@rm -Rf $(TMP)

clean:
	-@rm -f fullList
	-@rm -f workingList
	-@rm -f listServers
	-@rm -f listTemplates
	-@rm -f listTasks
	-@rm -f listJobs
	-@rm -f jobsList
	-@rm -f names.list
