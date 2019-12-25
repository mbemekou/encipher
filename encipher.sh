#!/bin/bash
$( grep "export DIR" ~/.bashrc) 
cat << EOF >/tmp/openssl.cnf


HOME			= \$DIR
RANDFILE		= \$DIR/.rnd
openssl_conf		= openssl_init

[ openssl_init ]
# Extra OBJECT IDENTIFIER info:
#oid_file		= \$DIR/.oid
oid_section		= new_oids
engines			= engine_section

[ new_oids ]


####################################################################
[ ca ]
default_ca	= CA_default		# The default ca section

####################################################################
[ CA_default ]

dir		= \$DIR	# Where everything is kept
certs		= \$DIR/certs		# Where the issued certs are kept
crl_dir		= \$DIR/crl			# Where the issued crl are kept
database	= \$DIR/index.txt	# database index file.
new_certs_dir	= \$DIR/newcerts			# default place for new certs.

certificate	= \$DIR/certs/ca.crt	 	# The CA certificate
serial		= \$DIR/serial 		# The current serial number
crl		= \$DIR/crl/crl.pem 		# The current CRL
private_key	= \$DIR/private/ca.key		# The private key
RANDFILE	= \$DIR/.rand		# private random number file

x509_extensions	= usr_cert		# The extentions to add to the cert


default_days	= 3650			# how long to certify for
default_crl_days= 30			# how long before next CRL
default_md	= sha256		# use public key default MD
preserve	= no			# keep passed DN ordering

policy		= policy_anything


[ policy_match ]
countryName		= match
stateOrProvinceName	= match
organizationName	= match
organizationalUnitName	= optional
commonName		= supplied
name			= optional
emailAddress		= optional


[ policy_anything ]
countryName		= optional
stateOrProvinceName	= optional
localityName		= optional
organizationName	= optional
organizationalUnitName	= optional
commonName		= supplied
name			= optional
emailAddress		= optional

####################################################################
[ req ]
default_bits		= \$KEY_SIZE
default_keyfile 	= privkey.pem
default_md		= sha256
distinguished_name	= req_distinguished_name
attributes		= req_attributes
x509_extensions	= v3_ca	# The extentions to add to the self signed cert


string_mask = nombstr


[ req_distinguished_name ]
countryName			= Country Name (2 letter code)
countryName_default		= \$COUNTRY
countryName_min			= 2
countryName_max			= 2

stateOrProvinceName		= State or Province Name (full name)
stateOrProvinceName_default	= \$PROVINCE

localityName			= Locality Name (eg, city)
localityName_default		= \$CITY

0.organizationName		= Organization Name (eg, company)
0.organizationName_default	= \$ORG


organizationalUnitName		= Organizational Unit Name (eg, section)
#organizationalUnitName_default	=

commonName			= Common Name (eg, your name or your server\'s hostname)
commonName_max			= 64

name				= Name
name_max			= 64

emailAddress			= Email Address
emailAddress_default		= \$EMAIL
emailAddress_max		= 40

# JY -- added for batch mode
organizationalUnitName_default = \$OU
commonName_default = \$CN
name_default = pki


# SET-ex3			= SET extension number 3

[ req_attributes ]
challengePassword		= A challenge password
challengePassword_min		= 4
challengePassword_max		= 20

unstructuredName		= An optional company name

[ usr_cert ]
basicConstraints=CA:FALSE
nsComment			= "encipher Generated Certificate"
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer:always
extendedKeyUsage=clientAuth
keyUsage = digitalSignature

[ server ]
basicConstraints=CA:FALSE
nsCertType                     = server
nsComment                      = "encipher Generated Server Certificate"
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer:always
extendedKeyUsage=serverAuth
keyUsage = digitalSignature, keyEncipherment

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment

[ v3_intermediate_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ ipsec ]
 basicConstraints = CA:FALSE
 keyUsage = nonRepudiation, digitalSignature, keyEncipherment, dataEncipherment, keyAgreement
 extendedKeyUsage =serverAuth, clientAuth
  subjectAltName = email:copy
 [ mail ]
 basicConstraints = CA:FALSE
 keyUsage = nonRepudiation, digitalSignature, keyEncipherment
 extendedKeyUsage = clientAuth,emailProtection
 subjectAltName = email:copy


[ v3_ca ]


# Extensions for a typical CA


# PKIX recommendation.

subjectKeyIdentifier=hash

authorityKeyIdentifier=keyid:always,issuer:always

# This is what PKIX recommends but some broken software chokes on critical
# extensions.
#basicConstraints = critical,CA:true
# So we do this instead.
basicConstraints = CA:true

# Key usage: this is typical for a CA certificate. However since it will
# prevent it being used as an test self-signed certificate it is best
# left out by default.
# keyUsage = cRLSign, keyCertSign

# Some might want this also
# nsCertType = sslCA, emailCA

# Include email address in subject alt name: another PKIX recommendation
# subjectAltName=email:copy
# Copy issuer details
# issuerAltName=issuer:copy

# DER hex encoding of an extension: beware experts only!
# obj=DER:02:03
# Where 'obj' is a standard or added object
# You can even override a supported extension:
# basicConstraints= critical, DER:30:03:01:01:FF

[ crl_ext ]

# CRL extensions.
# Only issuerAltName and authorityKeyIdentifier make any sense in a CRL.

# issuerAltName=issuer:copy
authorityKeyIdentifier=keyid:always,issuer:always

[ engine_section ]  


EOF


cat <<EOF > /tmp/vars
export CONF=\$DIR/openssl.cnf
export CERTS=\$DIR/certs
export CRL=\$DIR/crl
export REQUESTS=\$DIR/requests
export NEWCERTS=\$DIR/newcerts
export PRIVATE=\$DIR/private
export KEY_SIZE=2048 					
export CAKEY_SIZE=4096				
export DAYS=3650     				
export COUNTRY=FR     				
export PROVINCE=Seine-Maritime
export CITY=Rouen
export ORG=M2SSI
export EMAIL=ndembelekou@gmail.com
export OU=security
export CN=CA
EOF


#generate self-signed ca
create_ca()
{

	openssl req -x509 -newkey rsa:$CAKEY_SIZE -keyout $PRIVATE/ca.key -config $CONF -days $DAYS -out $CERTS/ca.crt -nodes || exit
	echo ""
	echo "your CA certificate can be found in:     $CERTS/ca.crt" 
	echo "your CA key can be found in:            $PRIVATE/ca.key"	
}
# generate intermediate  ca

create_intermediate_ca()
{
	openssl req  -newkey rsa:$CAKEY_SIZE -keyout $PRIVATE/"${CN}".key -config $CONF  -out $REQUESTS/"${CN}".req -days $DAYS -nodes
	openssl ca -in $REQUESTS/"${CN}".req -out $CERTS/"${CN}".crt -config $CONF -extensions v3_intermediate_ca  || exit
	echo ""
	echo "your intermediate CA certificate can be found in:     $CERTS/${CN}.crt " 
	echo "your intermediate CA key can be found in:            $PRIVATE/${CN}.key "

}
#generate client certificate

create_usr_cert()
{
	openssl req -newkey rsa:$KEY_SIZE -keyout $PRIVATE/"${CN}".key -config $CONF -out  $REQUESTS/"${CN}".req -nodes
	openssl ca -in $REQUESTS/"${CN}".req -out $CERTS/"${CN}".crt -config $CONF -extensions usr_cert
	openssl pkcs12 -in $CERTS/"${CN}".crt -inkey $PRIVATE/"${CN}".key -certfile $CERTS/ca.crt -export -out $CERTS/"${CN}".p12 || exit
	echo ""
	echo "your client certificate can be found in:     $CERTS/${CN}.crt " 
	echo "your client key can be found in:            $PRIVATE/${CN}.key"
	echo "your pkcs#12 archive client certificate can be found in:     $CERTS/${CN}.p12 " 

}

#generate ipsec peer certificate

create_ipsec_cert()
{
	openssl req -newkey rsa:$KEY_SIZE -keyout $PRIVATE/"${CN}".key -config $CONF -out  $REQUESTS/"${CN}".req -nodes
	openssl ca -in $REQUESTS/"${CN}".req -out $CERTS/"${CN}".crt -config $CONF -extensions ipsec
	openssl pkcs12 -in $CERTS/"${CN}".crt -inkey $PRIVATE/"${CN}".key -certfile $CERTS/ca.crt -export -out $CERTS/"${CN}".p12 || exit
	echo ""
	echo "your ipsec peer certificate can be found in:     $CERTS/${CN}.crt " 
	echo "your ipsec peer key can be found in:            $PRIVATE/${CN}.key"
	echo "your ipsec pkcs#12 archive  certificate can be found in:     $CERTS/${CN}.p12 " 

}

#generate email certificate

create_email_cert()
{
	openssl req -newkey rsa:$KEY_SIZE -keyout $PRIVATE/"${CN}".key -config $CONF -out  $REQUESTS/"${CN}".req -nodes
	openssl ca -in $REQUESTS/"${CN}".req -out $CERTS/"${CN}".crt -config $CONF -extensions mail
	openssl pkcs12 -in $CERTS/"${CN}".crt -inkey $PRIVATE/"${CN}".key -certfile $CERTS/ca.crt -export -out $CERTS/"${CN}".p12 
	echo ""
	echo "your email client certificate can be found in:     $CERTS/${CN}.crt " 
	echo "your email client key can be found in:            $PRIVATE/${CN}.key"
	echo "your email client pkcs#12 archive  certificate can be found in:     $CERTS/${CN}.p12 " 

}

#generate serveur certificate

create_server_cert()
{

	openssl req -newkey rsa:$KEY_SIZE -keyout $PRIVATE/"${CN}".key -config $CONF -out  $REQUESTS/"${CN}".req -nodes
	openssl ca -in $REQUESTS/"${CN}".req -out $CERTS/"${CN}".crt -config $CONF -extensions server
	openssl pkcs12 -in $CERTS/"${CN}".crt -inkey $PRIVATE/"${CN}".key -certfile $CERTS/ca.crt -export -out $CERTS/"${CN}".p12
	echo ""
	echo "your  ssl/openvpn server certificate can be found in:     $CERTS/${CN}.crt " 
	echo "your  ssl/openvpn server key can be found in:            $PRIVATE/${CN}.key"
	echo "your ssl/openvpn server  pkcs#12 archive  certificate can be found in:     $CERTS/${CN}.p12 "
}


dir_is_not_set()
{
	echo "please supply your pki directory. If you dont have pki directory create with command"
	echo "encipher --create-dir <pki_directory>"
	exit
}

cert_name_is_not_supplied()
{
	echo "please supply certificate name"
	exit
}
cert_serial_is_not_supplied()
{
	echo " please supply certificate serial number "
	exit
}

clean()
{
	echo "are you sure that you want to delete $DIR directory?"
	echo "this will delete all the content in that directory:  y or n? "
	read reponse
	case $reponse in
		y)
			echo $DIR
			rm -r ${DIR}
			for i in DIR CONF CERTS CRL REQUESTS NEWCERTS PRIVATE KEY_SIZE CAKEY_SIZE DAYS COUNTRY PROVINCE CITY ORG EMAIL OU CN ; do
				grep "export $i=" ~/.bashrc && sed -i "/export $i=.*/d"  ~/.bashrc  
	done
		;;
		n)
			exit
		;;
		*)
			echo "choose y or n"
			clean
		;;
	esac

}
revoke()
{
	openssl ca -revoke $DIR/newcerts/"${SERIAL}".pem && echo "the certificate has succesfully been revocated" || echo "error on certificate revocation please supply right certificate serial number"
	
}
create_cert_req()
{
	openssl req  -newkey rsa:$CAKEY_SIZE -keyout $PRIVATE/"${CN}".key -config $CONF  -out $REQUESTS/"${CN}".req -days $DAYS -nodes
	echo "your  request can be found in:     $REQUESTS/${CN}.req " 
	
}
sign_cert_req()
{
	echo "which kind of certificate you want to sign"
	echo "1-  ssl/openvpn client certificate"
	echo "2- ssl/openvpn server  certificate"
	echo "3- ipsec peer certificate"
	echo "4- email user certificate"
	echo "5- intermediate ca certificate"
	echo "Your choice:"
	read choice
	case $choice in
		1) 
			openssl ca -in "$DIR/requests/${REQ_NAME}.req" -out "$DIR/certs/${REQ_NAME}.crt" -config $CONF -extensions usr_cert
			echo "your  certificate can be found in:     $CERTS/${REQ_NAME}.crt " 

		;;
		2)
			openssl ca -in "$DIR/requests/${REQ_NAME}.req" -out "$DIR/certs/${REQ_NAME}.crt" -config $CONF -extensions server
			echo "your  certificate can be found in:     $CERTS/${REQ_NAME}.crt " 
		;;
		3)
			openssl ca -in "$DIR/requests/${REQ_NAME}.req" -out "$DIR/certs/${REQ_NAME}.crt" -config $CONF -extensions ipsec
			echo "your  certificate can be found in:     $CERTS/${REQ_NAME}.crt " 
		;;
		4)
			openssl ca -in "$DIR/requests/${REQ_NAME}.req" -out "$DIR/certs/${REQ_NAME}.crt" -config $CONF -extensions mail
			echo "your  certificate can be found in:     $CERTS/${REQ_NAME}.crt " 
		;;

		5)	openssl ca -in "$DIR/requests/${REQ_NAME}.req" -out "$DIR/certs/${REQ_NAME}.crt" -config $CONF -extensions	v3_intermediate_ca 
			echo "your  certificate can be found in:     $CERTS/${REQ_NAME}.crt " 
		;;
		
		*) 
			echo "invalid choice ! Please provide good choice"
	esac

}

variable_environ()
{
	
	for i in DIR CONF CERTS CRL REQUESTS NEWCERTS PRIVATE KEY_SIZE CAKEY_SIZE DAYS COUNTRY PROVINCE CITY ORG EMAIL OU CN ; do
		 j="${!i}"
	grep "export $i=" ~/.bashrc && sed -i "s+export $i=.*+export $i=${j}+1"  ~/.bashrc || echo export $i=${!i} >>~/.bashrc
	done

}

sourcer()
{
	
	cp $DIR/openssl.cnf /tmp/openssl.cnf
	sed -i "s;\$DIR;$DIR;g" $DIR/openssl.cnf
	for i in  CONF CERTS CRL REQUESTS NEWCERTS PRIVATE KEY_SIZE CAKEY_SIZE DAYS COUNTRY PROVINCE CITY ORG EMAIL OU; do
		$( grep "export $i" $DIR/vars ) 
		sed -i "s;\$$i;${!i};g" $DIR/openssl.cnf
	done
	sed -i "s;\$CN;$CN;g" $DIR/openssl.cnf

}
restore(){
	mv /tmp/openssl.cnf $DIR/openssl.cnf 
}

case $1 in
--mkdir)
			
			if [[ ! -z $2 ]]; then

				case $2 in 
					/*) 
						mkdir $2 || exit
						export DIR="${2}"
						mv /tmp/openssl.cnf $DIR/openssl.cnf
						mv /tmp/vars  $DIR/vars
						sed -i "s;\$DIR;$DIR;g" $DIR/vars
						source $DIR/vars
						variable_environ
						mkdir $DIR/certs $DIR/newcerts $DIR/private $DIR/crl $DIR/requests
						touch $DIR/index.txt $DIR/index.txt.attr $DIR/serial $DIR/.rnd
					;;
					*)	
						mkdir ${PWD}/${2} || exit
						export DIR="${PWD}/${2}"
						mv /tmp/openssl.cnf $DIR/openssl.cnf
						mv /tmp/vars  $DIR/vars
						sed -i "s;\$DIR;$DIR;g" $DIR/vars
						source $DIR/vars
						variable_environ
						mkdir $DIR/certs $DIR/newcerts $DIR/private $DIR/crl $DIR/requests
						touch $DIR/index.txt $DIR/index.txt.attr $DIR/serial $DIR/.rnd
						echo "0A0A" >$DIR/serial
				
					;;
				esac
			else
					echo "please supply a directory for your pki to be created"
					echo " Example:"
					echo " encipher --mkdir /root/ca"
			
			fi
													
;;
--dir)
			if [[ ! -z $2 ]]; then
			 	if [ -d $2 ]; then
					case $2 in
						/*) 
							grep "export DIR=" ~/.bashrc && sed -i "s+export DIR=.*+export DIR=$2+1"  ~/.bashrc || echo export DIR=$2 >>~/.bashrc
						;;
						*)
							export DIR="${PWD}/${2}"
							grep "export DIR=" ~/.bashrc && sed -i "s+export DIR=.*+export DIR=$DIR+1"  ~/.bashrc || echo export DIR=$DIR >>~/.bashrc

						;;
					esac
				else
					echo "directory does not exist"
				fi
			else
				echo "please supply valid pki directory. If you dont have pki directory create with command"
				echo "encipher --create-dir <pki_directory>"
			fi	
;;
--create-ca)

			if [[ ! -z "$DIR" ]];then	
					
				if [[ ! -z $2 ]]; then
					export CN=$2
					sourcer	
				else
					cert_name_is_not_supplied
				fi


			else
				
					dir_is_not_set
			fi
			create_ca
			restore
;;

--create-intermediate-ca)
			
			if [[ ! -z "$DIR" ]];then
				
				if [[ ! -z $2 ]]; then
					export CN=$2
					sourcer	
				else
					cert_name_is_not_supplied
				fi

			else
					dir_is_not_set
					
			fi

			create_intermediate_ca
			restore
			exit
;;


--create-client-cert)
			if [[ ! -z "$DIR" ]];then
				
				if [[ ! -z $2 ]]; then
					export CN=$2
					sourcer
				else
					cert_name_is_not_supplied
					
				fi

			else
					dir_is_not_set
			fi

			create_usr_cert
			restore
			exit
;;
--create-server-cert)
			if [[ ! -z "$DIR" ]];then
				
				if [[ ! -z $2 ]]; then
					export CN=$2
					sourcer
				else
					restore
					cert_name_is_not_supplied
					
				fi

			else
					dir_is_not_set
			fi

			create_server_cert
			restore
;;
--create-ipsec-cert) 
			if [[ ! -z "$DIR" ]];then
				
				if [[ ! -z $2 ]]; then
					export CN=$2
					sourcer
				else
		
					cert_name_is_not_supplied
				fi

			else
					dir_is_not_set
			fi

			create_ipsec_cert
;;
--create-mail-cert)
			if [[ ! -z "$DIR" ]];then
				
				if [[ ! -z $2 ]]; then
					export CN=$2
					sourcer
				else
					
					cert_name_is_not_supplied
				fi

			else
					dir_is_not_set
			fi

			create_email_cert
			restore
;;
--clean)
			if [[ ! -z "$DIR" ]];then
				clean

			else
				echo "please supply a directory to clean"
			fi
			exit
;;
--revoke)
			if [[ ! -z "$DIR" ]];then
				if [[ ! -z $2 ]]; then
					export SERIAL=$2
					revoke
				else
					cert_serial_is_not_supplied
				fi
			else
				dir_is_not_set
			fi
;;
--cert-request)
			if [[ ! -z "$DIR" ]];then
				
				if [[ ! -z $2 ]]; then
					export CN=$2
					sourcer
				else
					restore
					cert_name_is_not_supplied
				fi

			else
					
					dir_is_not_set
					
			fi

			create_cert_req
			restore
;;
--sign)
			if [[ ! -z "$DIR" ]];then
				
				if [[  ! -z $2  ]]; then
					export REQ_NAME=$2
					sourcer
				else
					cert_name_is_not_supplied
				fi

			else
					dir_is_not_set
					
			fi

			sign_cert_req
			restore
;;

*)
			clear
			echo "Usage:"
			echo ""
			echo "encipher --mkdir <your_pki_directory>"
			echo "encipher --dir <your_pki_directory>"
			echo "encipher --create-ca"
			echo "encipher --create-intermediate-ca <intermediate certificate's name>"
			echo "encipher --create-client-cert <ssl/openvpn user certificate's name>"
			echo "encipher --create-server-cert <ssl/openvpn server certificate's name>"
			echo "encipher --create-ipsec-cert <ipsec peer certificate's name>"
			echo "encipher --create-mail-cert <email certificate's name>"
			echo "encipher --revoke <certificate serial number>"
			echo "encipher --cert-request <certificate request name>"
			echo "encipher --clean "
			echo "encipher --sign <request> --ext <extensions>"
			echo ""
			echo "Examples:"
			echo ""
			echo " encipher --create-dir /root/cadir"
			echo "cd /root/cadir"
			echo "you must edit vars file to yours preferences"
			echo "encipher --create-ca"
			echo "encipher --create-server-cert server1"
			echo "encipher --create-usr-cert client1"
			echo "encipher --dir /root/ca"
			echo "encipher --revoke 01"
			echo "encipher --cert-request client2"
			echo "encipher --sign client2 "
;;
esac




 






