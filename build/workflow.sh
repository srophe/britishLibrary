# run the ant
ant

TEMPLATE_FILE="template.file"
DESTINATION_FILE="./path/to/destination/file.file"

# SECRET_KEY, $ADMIN_PASSWORD

sed \
    -e "s/\${SECRET_KEY}/$SECRET_KEY/" \
    $TEMPLATE_FILE > $DESTINATION_FILE
