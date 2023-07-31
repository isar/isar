if [ -z "$ISAR_VERSION" ]; then
    echo "ISAR_VERSION is not set";
    exit 2;
fi

find . -name "*.yaml" -exec sed -i "" "s/0.0.0-placeholder/$ISAR_VERSION/g" {} \; 
find . -name "*.dart" -exec sed -i "" "s/0.0.0-placeholder/$ISAR_VERSION/g" {} \; 
find . -name "*.json" -exec sed -i "" "s/0.0.0-placeholder/$ISAR_VERSION/g" {} \;
find . -name "*.md" -exec sed -i "" "s/0.0.0-placeholder/$ISAR_VERSION/g" {} \; 

echo "Adjusted versions to $ISAR_VERSION"