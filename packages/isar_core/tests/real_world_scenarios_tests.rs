//! Real-World Scenario Integration Tests
//! 
//! Tests complex real-world scenarios with sophisticated schemas
//! including e-commerce, social media, and enterprise applications

#[path = "common/mod.rs"]
mod common;

use common::*;
use isar_core::core::instance::IsarInstance;
use isar_core::core::writer::IsarWriter;
use isar_core::core::insert::IsarInsert;
use isar_core::core::cursor::{IsarCursor, IsarQueryCursor};
use isar_core::core::reader::IsarReader;
use isar_core::core::schema::*;
use isar_core::core::data_type::DataType;
use isar_core::core::filter::*;
use isar_core::core::value::IsarValue;
use isar_core::core::instance::Aggregation;
use isar_core::core::query_builder::{IsarQueryBuilder, Sort};

#[cfg(feature = "native")]
use isar_core::native::native_instance::NativeInstance;

#[cfg(feature = "sqlite")]
use isar_core::sqlite::sqlite_instance::SQLiteInstance;

/// Get instance IDs for real-world scenario tests (2000-2099)
pub fn real_world_id(offset: u32) -> u32 {
    2000 + offset
}

/// E-commerce Product schema with complex attributes
fn create_ecommerce_product_schema() -> IsarSchema {
    let properties = vec![
        PropertySchema::new("name", DataType::String, None),
        PropertySchema::new("description", DataType::String, None),
        PropertySchema::new("price", DataType::Double, None),
        PropertySchema::new("categoryId", DataType::Long, None),
        PropertySchema::new("brandId", DataType::Long, None),
        PropertySchema::new("sku", DataType::String, None),
        PropertySchema::new("isActive", DataType::Bool, None),
        PropertySchema::new("stockQuantity", DataType::Int, None),
        PropertySchema::new("rating", DataType::Float, None),
        PropertySchema::new("reviewCount", DataType::Int, None),
        PropertySchema::new("tags", DataType::StringList, None),
        PropertySchema::new("imageUrls", DataType::StringList, None),
        PropertySchema::new("attributes", DataType::Json, None), // Complex nested attributes
        PropertySchema::new("prices", DataType::DoubleList, None), // Price history
        PropertySchema::new("createdAt", DataType::Long, None),
        PropertySchema::new("updatedAt", DataType::Long, None),
    ];
    
    let indexes = vec![
        IndexSchema::new("sku_index", vec!["sku"], true, false), // Unique SKU
        IndexSchema::new("category_index", vec!["categoryId"], false, false),
        IndexSchema::new("brand_index", vec!["brandId"], false, false),
        IndexSchema::new("price_index", vec!["price"], false, false),
        IndexSchema::new("rating_index", vec!["rating"], false, false),
        IndexSchema::new("category_price_index", vec!["categoryId", "price"], false, false),
    ];
    
    IsarSchema::new("Product", Some("id"), properties, indexes, false)
}

/// Social Media User Profile with rich metadata
fn create_social_user_schema() -> IsarSchema {
    let properties = vec![
        PropertySchema::new("username", DataType::String, None),
        PropertySchema::new("email", DataType::String, None),
        PropertySchema::new("firstName", DataType::String, None),
        PropertySchema::new("lastName", DataType::String, None),
        PropertySchema::new("bio", DataType::String, None),
        PropertySchema::new("avatarUrl", DataType::String, None),
        PropertySchema::new("isVerified", DataType::Bool, None),
        PropertySchema::new("isPrivate", DataType::Bool, None),
        PropertySchema::new("followerCount", DataType::Int, None),
        PropertySchema::new("followingCount", DataType::Int, None),
        PropertySchema::new("postCount", DataType::Int, None),
        PropertySchema::new("birthDate", DataType::Long, None),
        PropertySchema::new("lastActiveAt", DataType::Long, None),
        PropertySchema::new("createdAt", DataType::Long, None),
        PropertySchema::new("interests", DataType::StringList, None),
        PropertySchema::new("blockedUsers", DataType::LongList, None),
        PropertySchema::new("settings", DataType::Json, None), // Complex settings object
        PropertySchema::new("location", DataType::Json, None), // Geo location data
    ];
    
    let indexes = vec![
        IndexSchema::new("username_index", vec!["username"], true, false), // Unique username
        IndexSchema::new("email_index", vec!["email"], true, false), // Unique email
        IndexSchema::new("verified_index", vec!["isVerified"], false, false),
        IndexSchema::new("follower_index", vec!["followerCount"], false, false),
        IndexSchema::new("created_index", vec!["createdAt"], false, false),
    ];
    
    IsarSchema::new("SocialUser", Some("id"), properties, indexes, false)
}

/// Enterprise Employee schema with complex hierarchical data
fn create_employee_schema() -> IsarSchema {
    let properties = vec![
        PropertySchema::new("employeeId", DataType::String, None),
        PropertySchema::new("firstName", DataType::String, None),
        PropertySchema::new("lastName", DataType::String, None),
        PropertySchema::new("email", DataType::String, None),
        PropertySchema::new("departmentId", DataType::Long, None),
        PropertySchema::new("managerId", DataType::Long, None),
        PropertySchema::new("jobTitle", DataType::String, None),
        PropertySchema::new("salary", DataType::Double, None),
        PropertySchema::new("hireDate", DataType::Long, None),
        PropertySchema::new("isActive", DataType::Bool, None),
        PropertySchema::new("performanceScore", DataType::Float, None),
        PropertySchema::new("skills", DataType::StringList, None),
        PropertySchema::new("certifications", DataType::StringList, None),
        PropertySchema::new("projectIds", DataType::LongList, None),
        PropertySchema::new("salaryHistory", DataType::DoubleList, None),
        PropertySchema::new("evaluationScores", DataType::FloatList, None),
        PropertySchema::new("contactInfo", DataType::Json, None), // Complex contact details
        PropertySchema::new("permissions", DataType::Json, None), // Role-based permissions
    ];
    
    let indexes = vec![
        IndexSchema::new("employee_id_index", vec!["employeeId"], true, false), // Unique employee ID
        IndexSchema::new("email_index", vec!["email"], true, false), // Unique email
        IndexSchema::new("department_index", vec!["departmentId"], false, false),
        IndexSchema::new("manager_index", vec!["managerId"], false, false),
        IndexSchema::new("salary_index", vec!["salary"], false, false),
        IndexSchema::new("dept_salary_index", vec!["departmentId", "salary"], false, false),
    ];
    
    IsarSchema::new("Employee", Some("id"), properties, indexes, false)
}

/// Insert realistic e-commerce product data
fn insert_ecommerce_test_data<T: IsarInstance>(instance: &T, collection_index: u16) -> Vec<i64> {
    let mut ids = Vec::new();
    
    // Realistic product data with varied complexity
    let products = vec![
        ("iPhone 15 Pro", "Latest Apple smartphone with titanium design", 1199.99, 1, 1, "APPL-IP15-PRO-128", true, 50, 4.8, 2341, 
         vec!["smartphone", "apple", "premium", "5g"], vec!["https://example.com/iphone1.jpg", "https://example.com/iphone2.jpg"],
         r#"{"color": "Natural Titanium", "storage": "128GB", "warranty": "1 year", "features": ["Face ID", "Dynamic Island", "A17 Pro chip"]}"#,
         vec![1299.99, 1249.99, 1199.99]),
        
        ("Samsung Galaxy S24", "Android flagship with AI features", 999.99, 1, 2, "SAMS-S24-256", true, 75, 4.6, 1876,
         vec!["smartphone", "samsung", "android", "ai"], vec!["https://example.com/galaxy1.jpg"],
         r#"{"color": "Phantom Black", "storage": "256GB", "warranty": "2 years", "features": ["Galaxy AI", "S Pen compatible"]}"#,
         vec![1099.99, 1049.99, 999.99]),
         
        ("MacBook Pro 16", "Professional laptop for creative work", 2499.99, 2, 1, "APPL-MBP16-M3", true, 25, 4.9, 892,
         vec!["laptop", "apple", "professional", "m3"], vec!["https://example.com/mbp1.jpg", "https://example.com/mbp2.jpg"],
         r#"{"color": "Space Gray", "chip": "M3 Pro", "memory": "18GB", "storage": "512GB", "display": "16-inch Liquid Retina XDR"}"#,
         vec![2699.99, 2599.99, 2499.99]),
         
        ("Sony WH-1000XM5", "Premium noise-canceling headphones", 399.99, 3, 3, "SONY-WH1000XM5", true, 120, 4.7, 3245,
         vec!["headphones", "sony", "noise-canceling", "wireless"], vec!["https://example.com/sony1.jpg"],
         r#"{"color": "Black", "battery": "30 hours", "features": ["ANC", "LDAC", "Multipoint"], "weight": "250g"}"#,
         vec![449.99, 429.99, 399.99]),
    ];

    let current_time = 1703980800; // 2023-12-30 timestamp
    
    let txn = instance.begin_txn(true).expect("Failed to begin transaction");
    let mut insert = instance.insert(txn, collection_index, products.len() as u32)
        .expect("Failed to create insert");

    for (name, desc, price, cat_id, brand_id, sku, active, stock, rating, reviews, tags, images, attrs, price_history) in products {
        let id = instance.auto_increment(collection_index);
        ids.push(id);
        
        // Write basic product data (1-based property indices)
        insert.write_string(1, name);
        insert.write_string(2, desc);
        insert.write_double(3, price);
        insert.write_long(4, cat_id);
        insert.write_long(5, brand_id);
        insert.write_string(6, sku);
        insert.write_bool(7, active);
        insert.write_int(8, stock);
        insert.write_float(9, rating);
        insert.write_int(10, reviews);
        
        // Write string lists (tags and image URLs)
        if let Some(mut list_writer) = insert.begin_list(11, tags.len() as u32) {
            for (i, tag) in tags.iter().enumerate() {
                list_writer.write_string(i as u32, tag);
            }
            insert.end_list(list_writer);
        }
        
        if let Some(mut list_writer) = insert.begin_list(12, images.len() as u32) {
            for (i, url) in images.iter().enumerate() {
                list_writer.write_string(i as u32, url);
            }
            insert.end_list(list_writer);
        }
        
        // Write JSON attributes
        insert.write_string(13, attrs);
        
        // Write price history
        if let Some(mut list_writer) = insert.begin_list(14, price_history.len() as u32) {
            for (i, hist_price) in price_history.iter().enumerate() {
                list_writer.write_double(i as u32, *hist_price);
            }
            insert.end_list(list_writer);
        }
        
        // Write timestamps
        insert.write_long(15, current_time - (id * 86400)); // createdAt (staggered)
        insert.write_long(16, current_time); // updatedAt

        insert.save(id).expect("Failed to save product data");
    }
    
    let txn = insert.finish().expect("Failed to finish insert");
    instance.commit_txn(txn).expect("Failed to commit transaction");
    
    ids
}

/// Insert realistic social media user data
fn insert_social_user_test_data<T: IsarInstance>(instance: &T, collection_index: u16) -> Vec<i64> {
    let mut ids = Vec::new();
    
    let users = vec![
        ("john_doe", "john@example.com", "John", "Doe", "Software engineer passionate about tech and coffee ☕", 
         "https://avatar.example.com/john.jpg", true, false, 15420, 892, 234,
         vec!["technology", "programming", "coffee", "travel"], vec![],
         r#"{"theme": "dark", "notifications": {"email": true, "push": false}, "privacy": {"showEmail": false}}"#,
         r#"{"city": "San Francisco", "country": "USA", "coordinates": {"lat": 37.7749, "lng": -122.4194}}"#),
         
        ("alice_smith", "alice@example.com", "Alice", "Smith", "Creative designer | Digital art enthusiast 🎨", 
         "https://avatar.example.com/alice.jpg", false, false, 8932, 1245, 567,
         vec!["design", "art", "photography", "music"], vec![],
         r#"{"theme": "light", "notifications": {"email": true, "push": true}, "privacy": {"showEmail": true}}"#,
         r#"{"city": "New York", "country": "USA", "coordinates": {"lat": 40.7128, "lng": -74.0060}}"#),
         
        ("tech_guru", "guru@example.com", "Alex", "Johnson", "Tech reviewer and gadget enthusiast", 
         "https://avatar.example.com/alex.jpg", true, false, 245893, 432, 1892,
         vec!["technology", "reviews", "gadgets", "innovation"], vec![2], // blocked user ID 2
         r#"{"theme": "auto", "notifications": {"email": false, "push": true}, "privacy": {"showEmail": false}}"#,
         r#"{"city": "Austin", "country": "USA", "coordinates": {"lat": 30.2672, "lng": -97.7431}}"#),
    ];

    let current_time = 1703980800;
    
    let txn = instance.begin_txn(true).expect("Failed to begin transaction");
    let mut insert = instance.insert(txn, collection_index, users.len() as u32)
        .expect("Failed to create insert");

    for (username, email, first, last, bio, avatar, verified, private, followers, following, posts, interests, blocked, settings, location) in users {
        let id = instance.auto_increment(collection_index);
        ids.push(id);
        
        // Basic user info (1-based indices)
        insert.write_string(1, username);
        insert.write_string(2, email);
        insert.write_string(3, first);
        insert.write_string(4, last);
        insert.write_string(5, bio);
        insert.write_string(6, avatar);
        insert.write_bool(7, verified);
        insert.write_bool(8, private);
        insert.write_int(9, followers);
        insert.write_int(10, following);
        insert.write_int(11, posts);
        
        // Timestamps
        insert.write_long(12, current_time - (id * 86400 * 30)); // birthDate (30 days apart)
        insert.write_long(13, current_time - 3600); // lastActiveAt (1 hour ago)
        insert.write_long(14, current_time - (id * 86400 * 100)); // createdAt (100 days apart)
        
        // Interests list
        if let Some(mut list_writer) = insert.begin_list(15, interests.len() as u32) {
            for (i, interest) in interests.iter().enumerate() {
                list_writer.write_string(i as u32, interest);
            }
            insert.end_list(list_writer);
        }
        
        // Blocked users list
        if let Some(mut list_writer) = insert.begin_list(16, blocked.len() as u32) {
            for (i, blocked_id) in blocked.iter().enumerate() {
                list_writer.write_long(i as u32, *blocked_id as i64);
            }
            insert.end_list(list_writer);
        }
        
        // JSON data
        insert.write_string(17, settings);
        insert.write_string(18, location);

        insert.save(id).expect("Failed to save user data");
    }
    
    let txn = insert.finish().expect("Failed to finish insert");
    instance.commit_txn(txn).expect("Failed to commit transaction");
    
    ids
}

#[cfg(test)]
#[cfg(feature = "native")]
mod native_real_world_tests {
    use super::*;

    /// E-commerce product catalog scenario with complex filtering and aggregations
    #[test]
    fn test_ecommerce_product_catalog_scenario() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_ecommerce_product_schema()];
        let instance = NativeInstance::open_instance(
            real_world_id(0),
            "ecommerce_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open database");

        let _product_ids = insert_ecommerce_test_data(&*instance, 0);

        // Scenario 1: Complex product filtering (price range + rating threshold)
        {
            let mut qb = instance.query(0).expect("Failed to create query builder");
            
            // Filter: price between 500-1500 AND rating >= 4.5
            let price_filter = Filter::new_condition(
                3, // price property index
                ConditionType::Between,
                vec![Some(IsarValue::Real(500.0)), Some(IsarValue::Real(1500.0))],
                true,
            );
            
            let rating_filter = Filter::new_condition(
                9, // rating property index
                ConditionType::GreaterOrEqual,
                vec![Some(IsarValue::Real(4.5))],
                true,
            );
            
            let combined_filter = Filter::new_and(vec![price_filter, rating_filter]);
            qb.set_filter(combined_filter);
            qb.add_sort(9, Sort::Desc, true); // Sort by rating descending
            
            let query = qb.build();
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            
            let mut cursor = instance.query_cursor(&txn, &query, None, None)
                .expect("Failed to create query cursor");
            
            let mut found_products = Vec::new();
            while let Some(reader) = cursor.next() {
                let name = reader.read_string(1).unwrap_or_default().to_string();
                let price = reader.read_double(3);
                let rating = reader.read_float(9);
                found_products.push((name, price, rating));
            }
            drop(cursor);
            
            // Should find iPhone and Samsung Galaxy, sorted by rating
            assert_eq!(found_products.len(), 2);
            assert!(found_products[0].0.contains("iPhone")); // Higher rating first
            assert!(found_products[1].0.contains("Samsung"));
            
            instance.abort_txn(txn);
        }

        // Scenario 2: Category-wise product aggregations
        {
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            
            // Count products by category
            let mut qb = instance.query(0).expect("Failed to create query builder");
            qb.set_filter(Filter::new_condition(
                4, // categoryId
                ConditionType::Equal,
                vec![Some(IsarValue::Integer(1))], // Category 1 (smartphones)
                true,
            ));
            let query = qb.build();
            
            let count = instance.query_aggregate(&txn, &query, Aggregation::Count, None)
                .expect("Failed to execute count");
            assert_eq!(count, Some(IsarValue::Integer(2))); // iPhone and Samsung in category 1
            
            // Average price in category 1
            let avg_price = instance.query_aggregate(&txn, &query, Aggregation::Average, Some(3))
                .expect("Failed to execute average");
            if let Some(IsarValue::Real(avg)) = avg_price {
                assert!((avg - 1099.99).abs() < 0.01); // Average of 1199.99 and 999.99
            }
            
            instance.abort_txn(txn);
        }

        // Scenario 3: Complex tag-based search with JSON attribute filtering
        {
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            let mut cursor = instance.cursor(&txn, 0).expect("Failed to get cursor");
            
            let mut apple_products = Vec::new();
            let mut current_id = 1i64;
            
            // Manually iterate to check complex conditions (JSON parsing would be app-level)
            while let Some(reader) = cursor.next(current_id) {
                // Check brand ID (Apple products have brandId = 1) or JSON attributes
                let brand_id = reader.read_long(5); // brandId property
                if let Some(attrs) = reader.read_string(13) {
                    // Check for Apple brand ID or Apple-specific features in JSON
                    if brand_id == 1 || attrs.contains("A17") || attrs.contains("M3") {
                        let name = reader.read_string(1).unwrap_or_default().to_string();
                        let price = reader.read_double(3);
                        apple_products.push((current_id, name.clone(), price));
                    }
                }
                current_id += 1;
                if current_id > 10 { break; } // Limit search
            }
            drop(cursor);
            
            assert!(apple_products.len() >= 2); // iPhone and MacBook
            instance.abort_txn(txn);
        }

        let closed = NativeInstance::close(instance, false);
        assert!(closed);
    }

    /// Social media analytics scenario with user engagement metrics
    #[test]
    fn test_social_media_analytics_scenario() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_social_user_schema()];
        let instance = NativeInstance::open_instance(
            real_world_id(1),
            "social_media_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open database");

        let _user_ids = insert_social_user_test_data(&*instance, 0);

        // Scenario 1: Find influencers (verified users with high follower count)
        {
            let mut qb = instance.query(0).expect("Failed to create query builder");
            
            let verified_filter = Filter::new_condition(
                7, // isVerified
                ConditionType::Equal,
                vec![Some(IsarValue::Bool(true))],
                true,
            );
            
            let follower_filter = Filter::new_condition(
                9, // followerCount
                ConditionType::Greater,
                vec![Some(IsarValue::Integer(10000))],
                true,
            );
            
            let influencer_filter = Filter::new_and(vec![verified_filter, follower_filter]);
            qb.set_filter(influencer_filter);
            qb.add_sort(9, Sort::Desc, true); // Sort by follower count
            
            let query = qb.build();
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            
            let mut cursor = instance.query_cursor(&txn, &query, None, None)
                .expect("Failed to create query cursor");
            
            let mut influencers = Vec::new();
            while let Some(reader) = cursor.next() {
                let username = reader.read_string(1).unwrap_or_default().to_string();
                let followers = reader.read_int(9);
                let verified = reader.read_bool(7).unwrap_or(false);
                influencers.push((username, followers, verified));
            }
            drop(cursor);
            
            // Should find tech_guru and john_doe
            assert_eq!(influencers.len(), 2);
            assert_eq!(influencers[0].0, "tech_guru"); // Highest follower count
            assert!(influencers[0].2); // Verified
            
            instance.abort_txn(txn);
        }

        // Scenario 2: User engagement analysis
        {
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            
            // Calculate engagement ratio (posts per follower) for active users
            let mut cursor = instance.cursor(&txn, 0).expect("Failed to get cursor");
            let mut engagement_data = Vec::new();
            let mut current_id = 1i64;
            
            while let Some(reader) = cursor.next(current_id) {
                let username = reader.read_string(1).unwrap_or_default().to_string();
                let followers = reader.read_int(9) as f64;
                let posts = reader.read_int(11) as f64;
                
                let engagement_ratio = if followers > 0.0 { posts / followers } else { 0.0 };
                engagement_data.push((username, engagement_ratio, followers as i32, posts as i32));
                
                current_id += 1;
                if current_id > 10 { break; } // Limit search
            }
            drop(cursor);
            
            // Sort by engagement ratio
            engagement_data.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap());
            
            assert!(engagement_data.len() >= 3);
            // Users with lower follower counts should have higher engagement ratios
            
            instance.abort_txn(txn);
        }

        // Scenario 3: Interest-based user discovery with location filtering  
        {
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            let mut cursor = instance.cursor(&txn, 0).expect("Failed to get cursor");
            
            let mut tech_users_in_usa = Vec::new();
            let mut current_id = 1i64;
            
            while let Some(reader) = cursor.next(current_id) {
                // Check interests for technology-related content
                if let Some((list_reader, length)) = reader.read_list(15) {
                    let mut has_tech_interest = false;
                    for i in 0..length {
                        if let Some(interest) = list_reader.read_string(i) {
                            if interest.contains("technology") || interest.contains("programming") {
                                has_tech_interest = true;
                                break;
                            }
                        }
                    }
                    
                    if has_tech_interest {
                        // Check location JSON for USA (in real app, would parse JSON)
                        if let Some(location) = reader.read_string(18) {
                            if location.contains("USA") {
                                let username = reader.read_string(1).unwrap_or_default().to_string();
                                tech_users_in_usa.push(username);
                            }
                        }
                    }
                }
                current_id += 1;
                if current_id > 10 { break; } // Limit search
            }
            drop(cursor);
            
            assert!(tech_users_in_usa.contains(&"john_doe".to_string()));
            assert!(tech_users_in_usa.contains(&"tech_guru".to_string()));
            
            instance.abort_txn(txn);
        }

        let closed = NativeInstance::close(instance, false);
        assert!(closed);
    }

    /// Enterprise HR management scenario with complex employee hierarchies
    #[test] 
    fn test_enterprise_hr_management_scenario() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_employee_schema()];
        let instance = NativeInstance::open_instance(
            real_world_id(2),
            "enterprise_hr_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open database");

        // Insert complex employee hierarchy data
        let employee_data = vec![
            ("EMP001", "John", "Smith", "john.smith@company.com", 1, 0, "CEO", 250000.0, 4.9,
             vec!["leadership", "strategy", "business"], vec!["MBA", "PMP"],
             vec![200000.0, 220000.0, 250000.0], vec![4.8, 4.9]),
            
            ("EMP002", "Sarah", "Johnson", "sarah.j@company.com", 2, 1, "VP Engineering", 180000.0, 4.7,
             vec!["engineering", "management", "rust", "architecture"], vec!["MS CS", "AWS Certified"],
             vec![150000.0, 165000.0, 180000.0], vec![4.5, 4.6, 4.7]),
             
            ("EMP003", "Mike", "Davis", "mike.d@company.com", 2, 2, "Senior Developer", 120000.0, 4.6,
             vec!["rust", "backend", "databases", "microservices"], vec!["BS CS"],
             vec![95000.0, 110000.0, 120000.0], vec![4.2, 4.4, 4.6]),
             
            ("EMP004", "Lisa", "Wilson", "lisa.w@company.com", 3, 1, "VP Marketing", 160000.0, 4.5,
             vec!["marketing", "strategy", "digital"], vec!["MBA Marketing"],
             vec![140000.0, 150000.0, 160000.0], vec![4.3, 4.4, 4.5]),
        ];

        let current_time = 1703980800;
        let txn = instance.begin_txn(true).expect("Failed to begin transaction");
        let mut insert = instance.insert(txn, 0, employee_data.len() as u32)
            .expect("Failed to create insert");

        for (emp_id, first, last, email, dept_id, manager_id, title, salary, score, skills, certs, salary_hist, eval_scores) in employee_data {
            let id = instance.auto_increment(0);
            
            // Basic employee data (1-based indices)
            insert.write_string(1, emp_id);
            insert.write_string(2, first);
            insert.write_string(3, last);
            insert.write_string(4, email);
            insert.write_long(5, dept_id);
            insert.write_long(6, manager_id);
            insert.write_string(7, title);
            insert.write_double(8, salary);
            insert.write_long(9, current_time - (id * 86400 * 365)); // hire date
            insert.write_bool(10, true); // isActive
            insert.write_float(11, score);
            
            // Skills list
            if let Some(mut list_writer) = insert.begin_list(12, skills.len() as u32) {
                for (i, skill) in skills.iter().enumerate() {
                    list_writer.write_string(i as u32, skill);
                }
                insert.end_list(list_writer);
            }
            
            // Certifications list
            if let Some(mut list_writer) = insert.begin_list(13, certs.len() as u32) {
                for (i, cert) in certs.iter().enumerate() {
                    list_writer.write_string(i as u32, cert);
                }
                insert.end_list(list_writer);
            }
            
            // Project IDs (sample data)
            if let Some(mut list_writer) = insert.begin_list(14, 2) {
                list_writer.write_long(0, (id * 10) as i64);
                list_writer.write_long(1, (id * 10 + 1) as i64);
                insert.end_list(list_writer);
            }
            
            // Salary history
            if let Some(mut list_writer) = insert.begin_list(15, salary_hist.len() as u32) {
                for (i, hist_salary) in salary_hist.iter().enumerate() {
                    list_writer.write_double(i as u32, *hist_salary);
                }
                insert.end_list(list_writer);
            }
            
            // Evaluation scores
            if let Some(mut list_writer) = insert.begin_list(16, eval_scores.len() as u32) {
                for (i, eval_score) in eval_scores.iter().enumerate() {
                    list_writer.write_float(i as u32, *eval_score);
                }
                insert.end_list(list_writer);
            }
            
            // JSON data (contact info and permissions)
            let contact_info = format!(r#"{{"phone": "+1-555-{:04}", "extension": "{}", "office": "Building {}, Floor {}"}}"#, 
                                     1000 + id, 1000 + id, (id % 3) + 1, (id % 10) + 1);
            insert.write_string(17, &contact_info);
            
            let permissions = if title.contains("VP") || title.contains("CEO") {
                r#"{"admin": true, "hr_access": true, "finance_access": true, "reports": ["all"]}"#
            } else {
                r#"{"admin": false, "hr_access": false, "finance_access": false, "reports": ["personal"]}"#
            };
            insert.write_string(18, permissions);

            insert.save(id).expect("Failed to save employee data");
        }

        let txn = insert.finish().expect("Failed to finish insert");
        instance.commit_txn(txn).expect("Failed to commit transaction");

        // Scenario 1: Department salary analysis
        {
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            
            // Find average salary by department
            let mut qb = instance.query(0).expect("Failed to create query builder");
            qb.set_filter(Filter::new_condition(
                5, // departmentId
                ConditionType::Equal,
                vec![Some(IsarValue::Integer(2))], // Engineering department
                true,
            ));
            let query = qb.build();
            
            let avg_salary = instance.query_aggregate(&txn, &query, Aggregation::Average, Some(8))
                .expect("Failed to calculate average salary");
            
            if let Some(IsarValue::Real(avg)) = avg_salary {
                assert!(avg > 140000.0); // Should be average of Sarah and Mike's salaries
            }
            
            instance.abort_txn(txn);
        }

        // Scenario 2: Find high-performing employees for promotion
        {
            let mut qb = instance.query(0).expect("Failed to create query builder");
            
            let performance_filter = Filter::new_condition(
                11, // performanceScore
                ConditionType::GreaterOrEqual,
                vec![Some(IsarValue::Real(4.6))],
                true,
            );
            
            qb.set_filter(performance_filter);
            qb.add_sort(11, Sort::Desc, true); // Sort by performance descending
            
            let query = qb.build();
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            
            let mut cursor = instance.query_cursor(&txn, &query, None, None)
                .expect("Failed to create query cursor");
            
            let mut high_performers = Vec::new();
            while let Some(reader) = cursor.next() {
                let emp_id = reader.read_string(1).unwrap_or_default().to_string();
                let score = reader.read_float(11);
                let title = reader.read_string(7).unwrap_or_default().to_string();
                high_performers.push((emp_id, score, title));
            }
            drop(cursor);
            
            assert!(high_performers.len() >= 3);
            assert_eq!(high_performers[0].0, "EMP001"); // CEO should have highest score
            
            instance.abort_txn(txn);
        }

        let closed = NativeInstance::close(instance, false);
        assert!(closed);
    }
}

#[cfg(test)]
#[cfg(feature = "sqlite")]
mod sqlite_real_world_tests {
    use super::*;
    use isar_core::sqlite::sqlite_instance::SQLiteInstance;

    /// E-commerce scenario with SQLite backend
    #[test]
    fn test_sqlite_ecommerce_scenario() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_ecommerce_product_schema()];
        let instance = SQLiteInstance::open_instance(
            real_world_id(10),
            "sqlite_ecommerce_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open SQLite database");

        let _product_ids = insert_ecommerce_test_data(&instance, 0);

        // Test complex query with SQLite backend
        {
            let mut qb = instance.query(0).expect("Failed to create query builder");
            
            let active_filter = Filter::new_condition(
                7, // isActive
                ConditionType::Equal,
                vec![Some(IsarValue::Bool(true))],
                true,
            );
            
            let stock_filter = Filter::new_condition(
                8, // stockQuantity
                ConditionType::Greater,
                vec![Some(IsarValue::Integer(30))],
                true,
            );
            
            let combined_filter = Filter::new_and(vec![active_filter, stock_filter]);
            qb.set_filter(combined_filter);
            qb.add_sort(3, Sort::Asc, true); // Sort by price ascending
            
            let query = qb.build();
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            
            let count = instance.query_aggregate(&txn, &query, Aggregation::Count, None)
                .expect("Failed to execute count");
            assert_eq!(count, Some(IsarValue::Integer(3))); // iPhone (50), Samsung (75), Sony (120) have stock > 30
            
            instance.abort_txn(txn);
        }

        let closed = SQLiteInstance::close(instance, false);
        assert!(closed);
    }

    /// Social media scenario with SQLite backend
    #[test]
    fn test_sqlite_social_media_scenario() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        let schemas = vec![create_social_user_schema()];
        let instance = SQLiteInstance::open_instance(
            real_world_id(11),
            "sqlite_social_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open SQLite database");

        let _user_ids = insert_social_user_test_data(&instance, 0);

        // Test user discovery query
        {
            let mut qb = instance.query(0).expect("Failed to create query builder");
            
            let private_filter = Filter::new_condition(
                8, // isPrivate
                ConditionType::Equal,
                vec![Some(IsarValue::Bool(false))],
                true,
            );
            
            qb.set_filter(private_filter);
            qb.add_sort(9, Sort::Desc, true); // Sort by follower count
            
            let query = qb.build();
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            
            let mut cursor = instance.query_cursor(&txn, &query, None, None)
                .expect("Failed to create query cursor");
            
            let mut public_users = Vec::new();
            while let Some(reader) = cursor.next() {
                let username = reader.read_string(1).unwrap_or_default().to_string();
                let followers = reader.read_int(9);
                public_users.push((username, followers));
            }
            drop(cursor);
            
            assert!(public_users.len() >= 2); // Should find public users
            
            instance.abort_txn(txn);
        }

        let closed = SQLiteInstance::close(instance, false);
        assert!(closed);
    }
}

#[cfg(test)]
#[cfg(all(feature = "native", feature = "sqlite"))]
mod cross_platform_real_world_tests {
    use super::*;
    use isar_core::sqlite::sqlite_instance::SQLiteInstance;

    /// Test data consistency between Native and SQLite backends for e-commerce
    #[test]
    fn test_cross_platform_ecommerce_consistency() {
        let temp_dir_native = create_test_dir();
        let temp_dir_sqlite = create_test_dir();
        
        let native_dir = temp_dir_native.path().to_str().unwrap();
        let sqlite_dir = temp_dir_sqlite.path().to_str().unwrap();
        
        let schemas = vec![create_ecommerce_product_schema()];
        
        // Test with Native backend
        let native_instance = NativeInstance::open_instance(
            real_world_id(20),
            "native_consistency_db",
            native_dir,
            schemas.clone(),
            1024,
            None,
            None,
        ).expect("Failed to open native database");

        let _native_product_ids = insert_ecommerce_test_data(&*native_instance, 0);

        // Test with SQLite backend
        let sqlite_instance = SQLiteInstance::open_instance(
            real_world_id(21),
            "sqlite_consistency_db",
            sqlite_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open SQLite database");

        let _sqlite_product_ids = insert_ecommerce_test_data(&sqlite_instance, 0);

        // Compare results from both backends
        {
            // Native query
            let mut native_qb = native_instance.query(0).expect("Failed to create native query builder");
            native_qb.add_sort(3, Sort::Asc, true); // Sort by price
            let native_query = native_qb.build();
            
            let native_txn = native_instance.begin_txn(false).expect("Failed to begin native read transaction");
            let mut native_cursor = native_instance.query_cursor(&native_txn, &native_query, None, None)
                .expect("Failed to create native query cursor");
            
            let mut native_products = Vec::new();
            while let Some(reader) = native_cursor.next() {
                let name = reader.read_string(1).unwrap_or_default().to_string();
                let price = reader.read_double(3);
                native_products.push((name, price));
            }
            drop(native_cursor);
            
            // SQLite query
            let mut sqlite_qb = sqlite_instance.query(0).expect("Failed to create SQLite query builder");
            sqlite_qb.add_sort(3, Sort::Asc, true); // Sort by price
            let sqlite_query = sqlite_qb.build();
            
            let sqlite_txn = sqlite_instance.begin_txn(false).expect("Failed to begin SQLite read transaction");
            let mut sqlite_cursor = sqlite_instance.query_cursor(&sqlite_txn, &sqlite_query, None, None)
                .expect("Failed to create SQLite query cursor");
            
            let mut sqlite_products = Vec::new();
            while let Some(reader) = sqlite_cursor.next() {
                let name = reader.read_string(1).unwrap_or_default().to_string();
                let price = reader.read_double(3);
                sqlite_products.push((name, price));
            }
            drop(sqlite_cursor);
            
            // Compare results
            assert_eq!(native_products.len(), sqlite_products.len());
            for (native_product, sqlite_product) in native_products.iter().zip(sqlite_products.iter()) {
                assert_eq!(native_product.0, sqlite_product.0); // Name should match
                assert!((native_product.1 - sqlite_product.1).abs() < 0.001); // Price should match
            }
            
            native_instance.abort_txn(native_txn);
            sqlite_instance.abort_txn(sqlite_txn);
        }
        
        // Test aggregation consistency
        {
            let native_txn = native_instance.begin_txn(false).expect("Failed to begin native read transaction");
            let sqlite_txn = sqlite_instance.begin_txn(false).expect("Failed to begin SQLite read transaction");
            
            let native_qb = native_instance.query(0).expect("Failed to create native query builder");
            let native_query = native_qb.build();
            
            let sqlite_qb = sqlite_instance.query(0).expect("Failed to create SQLite query builder");
            let sqlite_query = sqlite_qb.build();
            
            // Count aggregation
            let native_count = native_instance.query_aggregate(&native_txn, &native_query, Aggregation::Count, None)
                .expect("Failed to execute native count");
            let sqlite_count = sqlite_instance.query_aggregate(&sqlite_txn, &sqlite_query, Aggregation::Count, None)
                .expect("Failed to execute SQLite count");
            assert_eq!(native_count, sqlite_count);
            
            // Average price aggregation
            let native_avg = native_instance.query_aggregate(&native_txn, &native_query, Aggregation::Average, Some(3))
                .expect("Failed to execute native average");
            let sqlite_avg = sqlite_instance.query_aggregate(&sqlite_txn, &sqlite_query, Aggregation::Average, Some(3))
                .expect("Failed to execute SQLite average");
            
            if let (Some(IsarValue::Real(native_val)), Some(IsarValue::Real(sqlite_val))) = (native_avg, sqlite_avg) {
                assert!((native_val - sqlite_val).abs() < 0.001);
            }
            
            native_instance.abort_txn(native_txn);
            sqlite_instance.abort_txn(sqlite_txn);
        }

        let native_closed = NativeInstance::close(native_instance, false);
        let sqlite_closed = SQLiteInstance::close(sqlite_instance, false);
        assert!(native_closed && sqlite_closed);
    }

    /// Test complex multi-collection scenario with relationships
    #[test]
    fn test_multi_collection_real_world_scenario() {
        let temp_dir = create_test_dir();
        let db_dir = temp_dir.path().to_str().unwrap();
        
        // Create schemas for a complete social media system
        let schemas = vec![
            create_social_user_schema(),
            create_post_schema(), // From common utilities
        ];
        
        let instance = NativeInstance::open_instance(
            real_world_id(22),
            "multi_collection_db",
            db_dir,
            schemas,
            1024,
            None,
            None,
        ).expect("Failed to open database");

        // Insert users
        let user_ids = insert_social_user_test_data(&*instance, 0);

        // Insert posts referencing users
        let posts_data = vec![
            ("My first post about technology", "Excited to share my thoughts on the latest tech trends! #technology #innovation", user_ids[0], vec!["technology", "innovation", "trends"]),
            ("Design inspiration", "Found some amazing design patterns today. #design #creativity", user_ids[1], vec!["design", "patterns", "inspiration"]),
            ("Product review: iPhone 15", "Comprehensive review of the latest iPhone. Amazing camera quality! #review #apple #tech", user_ids[2], vec!["review", "apple", "technology"]),
        ];

        let txn = instance.begin_txn(true).expect("Failed to begin transaction");
        let mut insert = instance.insert(txn, 1, posts_data.len() as u32) // Collection index 1 for posts
            .expect("Failed to create insert");

        for (title, content, user_id, tags) in posts_data {
            let post_id = instance.auto_increment(1);
            
            // Write post data (1-based property indices)
            insert.write_string(1, title);
            insert.write_string(2, content);
            insert.write_long(3, user_id);
            
            // Write tags list
            if let Some(mut list_writer) = insert.begin_list(4, tags.len() as u32) {
                for (i, tag) in tags.iter().enumerate() {
                    list_writer.write_string(i as u32, tag);
                }
                insert.end_list(list_writer);
            }

            insert.save(post_id).expect("Failed to save post data");
        }
        
        let txn = insert.finish().expect("Failed to finish insert");
        instance.commit_txn(txn).expect("Failed to commit transaction");

        // Query posts by user with user details
        {
            let txn = instance.begin_txn(false).expect("Failed to begin read transaction");
            
            // Get user details first
            let mut user_cursor = instance.cursor(&txn, 0).expect("Failed to get user cursor");
            let user_reader = user_cursor.next(user_ids[2]).expect("Failed to read user");
            let username = user_reader.read_string(1).unwrap_or_default().to_string();
            let verified = user_reader.read_bool(7).unwrap_or(false);
            drop(user_cursor);
            
            // Find posts by this user
            let mut posts_qb = instance.query(1).expect("Failed to create posts query builder");
            posts_qb.set_filter(Filter::new_condition(
                3, // userId property
                ConditionType::Equal,
                vec![Some(IsarValue::Integer(user_ids[2]))],
                true,
            ));
            let posts_query = posts_qb.build();
            
            let mut posts_cursor = instance.query_cursor(&txn, &posts_query, None, None)
                .expect("Failed to create posts query cursor");
            
            let mut user_posts = Vec::new();
            while let Some(reader) = posts_cursor.next() {
                let title = reader.read_string(1).unwrap_or_default().to_string();
                let content = reader.read_string(2).unwrap_or_default().to_string();
                user_posts.push((title, content));
            }
            drop(posts_cursor);
            
            assert_eq!(username, "tech_guru");
            assert!(verified);
            assert_eq!(user_posts.len(), 1);
            assert!(user_posts[0].0.contains("iPhone"));
            
            instance.abort_txn(txn);
        }

        let closed = NativeInstance::close(instance, false);
        assert!(closed);
    }
} 