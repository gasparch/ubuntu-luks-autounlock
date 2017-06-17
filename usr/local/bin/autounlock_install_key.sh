#!/bin/bash

mkdir -p /run/keytemp
LOCK_FILE="/run/keytemp/lock_key"

function finish {
	rm -f $LOCK_FILE
}
trap finish EXIT


echo "Generates key based on your Wifi MAC address and infromation from your external monitor"
echo "If you do not have external monitor attached, please turn it off in /usr/local/etc/auto_unlock.conf"
echo "It can decrease security of auto unlock because Wifi MAC is visible to everyone in proximity of your location."

. /usr/local/etc/auto_unlock.conf

if [ "$KEYSLOT" = "0" ]; then
	echo "Cannot use key slot 0"
	exit 10
fi

echo "Looking up AP MAC for Wifi network $WIFI_NETWORK"

WIFI_MAC=`iwlist scanning 2>/dev/null | egrep 'Address|ESSID' | grep -B1 'ESSID:"'"${WIFI_NETWORK}"'"' | awk -F'Address: ' '/Address/ {print $2}'`

echo "Found MAC ==  |$WIFI_MAC| "

EDID_LINES=`get-edid 2>/dev/null | parse-edid | egrep 'Identifier|ModelName|VendorName|Manufactured week|DisplaySize' | LANG=C sort `

echo "Gathered display information"
echo -e "--------\n${EDID_LINES}\n-----------\n"

echo "Please verify that Wifi MAC of Access Point and display information are valid"
echo "Especially verify that your external display is recognized, not build-in one"

echo "Type in YES to set-up LUKS key based on information above"
read ANSWER

if [ "$ANSWER" != "YES" ]; then
	echo "Exiting without setup"
	exit 5
fi

echo -e "$WIFI_MAC\n$EDID_LINES" > $LOCK_FILE
echo "Checksum of lockfile $(md5sum $LOCK_FILE)"
echo "Stored lock file in $LOCK_FILE, please delete it manually if you cancel script execution"

echo "Parsing /etc/crypttab"

for TEXT in $(awk '/^..*$/ {print $1 ":" $2}' /etc/crypttab); do
	
	NAME=`echo "$TEXT" | cut -d: -f1`
	DEVICE=`echo "$TEXT" | cut -d: -f2`

	case $DEVICE in
		/dev/*) ;;
		UUID=*) UUID=${DEVICE##UUID=} 
			DEVICE=$(blkid -U "$UUID")
		;;
	esac

	if [ -z "$DEVICE" ]; then
		continue
	fi

	echo "found partition $DEVICE for $NAME"

	if [ ! -b $DEVICE ]; then
		echo "Cannot work on $DEVICE, not a block device"
		continue
	fi

	SLOTS=`cryptsetup luksDump $DEVICE | grep '^Key Slot'`
	SLOT_USAGE=`echo "$SLOTS" | grep "Key Slot $KEYSLOT"`

	echo -e "slots usage for $DEVICE\n------\n${SLOTS}\n---------\n"

	SLOT_OK=
	case "$SLOT_USAGE" in 
		*DISABLED) SLOT_OK=1 ;;
		*ENABLED)
			echo "Slot $KEYSLOT is used for device $NAME $DEVICE"
			echo "Do you want to override it? Type YES to override"
			read ANSWER
			if [ "$ANSWER" != "YES" ]; then
				echo "Not overriding ..."
				continue
			fi
			cryptsetup luksKillSlot $DEVICE $KEYSLOT
			SLOT_OK=1
	esac

	if [ "$SLOT_OK" = "1" ]; then
		cryptsetup luksAddKey --key-slot $KEYSLOT $DEVICE $LOCK_FILE
	fi

done


