use std::fs::File;
use std::io::{self, BufRead};
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::{Duration, Instant};
use serde_json::json;

fn main() -> io::Result<()> {
    // Read URLs from input file
    let file = File::open("input_urls.txt")?;
    let urls: Vec<String> = io::BufReader::new(file)
        .lines()
        .filter_map(Result::ok)
        .collect();

    let log = Arc::new(Mutex::new(Vec::new())); // Shared log
    let mut handles = Vec::new();

    // Spawn threads for parallel processing
    for (i, url) in urls.into_iter().enumerate() {
        let log_clone = Arc::clone(&log);
        let handle = thread::spawn(move || {
            let thread_id = i % 4; // Simulate 4 threads
            let start = Instant::now();

            // Simulate download with sleep
            thread::sleep(Duration::from_millis(500 + (i as u64) * 100));

            let duration = start.elapsed().as_millis();
            let entry = json!({
                "url": url,
                "thread": thread_id,
                "time_ms": duration,
                "status": "success"
            });

            log_clone.lock().unwrap().push(entry);
        });
        handles.push(handle);
    }

    // Wait for all threads to finish
    for handle in handles {
        handle.join().unwrap();
    }

    // Write JSON log to file
    let log_guard = log.lock().unwrap();
    let json_log = serde_json::to_string_pretty(&*log_guard)?;
    std::fs::write("log.json", json_log)?;

    println!("Download simulation complete. Log saved to log.json");
    Ok(())
}