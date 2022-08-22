pub fn get_dir() -> Option<String> {
    Some(dirs::config_dir()?.to_str()?.to_string())
}

pub fn get_app_id() -> Option<String> {
    Some(String::new())
}
