
ls: lsServers

codelets:
	$(eval API_KEY := $(shell cat API_KEY))
	curl -X GET "https://apis.codero.com/cloud/v1/codelets" \
	-H "Authorization: $(API_KEY)" \
	-m 30 \
	-v > codelets

oss: API_KEY OS RAM
	$(eval OS := $(shell cat OS))
	$(eval RAM := $(shell cat RAM))
	$(eval API_KEY := $(shell cat API_KEY))
	curl -X GET "https://apis.codero.com/cloud/v1/codelets/os" \
	-H "Authorization: $(API_KEY)" \
	-m 30 \
	-v > oss

picky: API_KEY OS RAM
	$(eval OS := $(shell cat OS))
	$(eval RAM := $(shell cat RAM))
	$(eval API_KEY := $(shell cat API_KEY))
	curl -X GET "https://apis.codero.com/cloud/v1/codelets?ram=$(RAM)&os=$(OS)" \
	-H "Authorization: $(API_KEY)" \
	-m 30 \
	-v > picky

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

create:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval PWD := $(shell pwd))
	$(eval API_KEY := $(shell cat API_KEY))
	$(eval CODELETID := $(shell cat CODELETID))
	$(eval URL := https://apis.codero.com/cloud/v1/servers/)
	$(eval DATA :=key=$(API_KEY)&login=$(API_USERNAME)&action=reset)
	echo -n "curl -X POST $(URL) " >> $(TMP)/working.sh ; \
	echo -n '-H "Authorization: $(API_KEY)" ' >> $(TMP)/working.sh ; \
	echo -n '-H "Content-Type: application/json" ' >> $(TMP)/working.sh ; \
	echo -n '-d "{\"name\":\"www1\",\"codelet\":\"$(CODELETID)\"}" ' >> $(TMP)/working.sh ; \
	echo -n '-m 30 ' >> $(TMP)/working.sh ; \
	echo "-v > $(TMP)/jobby" >> $(TMP)/working.sh ; \
	bash $(TMP)/working.sh
	cat $(TMP)/working.sh
	cat $(TMP)/jobby | jq .
	@rm -Rf $(TMP)

RAM:
	@while [ -z "$$RAM" ]; do \
		read -r -p "Enter the amount of RAM in MB you wish to associate with this server [RAM]: " RAM; echo "$$RAM">>RAM; cat RAM; \
	done ;

OS:
	@while [ -z "$$OS" ]; do \
		read -r -p "Enter the OS you wish to associate with this server [OS]: " OS; echo "$$OS">>OS; cat OS; \
	done ;

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
		echo "-v > $(TMP)/jobby" ; \
		done < workingList > $(TMP)/working.sh
	-/usr/bin/time parallel  --jobs 2 -- < $(TMP)/working.sh
	cat $(TMP)/working.sh
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
		done < workingList > $(TMP)/working.sh
	-/usr/bin/time parallel  --jobs 2 -- < $(TMP)/working.sh
	cat $(TMP)/working.sh
	cat $(TMP)/jobby | jq .
	@rm -Rf $(TMP)

clean:
	-@rm -f fullList
	-@rm -f workingList
	-@rm -f listServers
	-@rm -f listTemplates
	-@rm -f listTasks
	-@rm -f listJobs
	-@rm -f jobsList
	-@rm -f picky
	-@rm -f oss
	-@rm -f names.list
