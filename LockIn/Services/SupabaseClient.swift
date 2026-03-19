import Foundation
import Supabase

/// Global Supabase client instance. Configure URL and key in Constants.swift.
/// Uses a lazy pattern so the app doesn't crash if credentials aren't set yet.
let supabase: SupabaseClient = {
    guard let url = URL(string: AppConstants.supabaseURL),
          AppConstants.supabaseURL != "YOUR_SUPABASE_URL" else {
        // Return a client pointing to localhost — API calls will fail gracefully
        // instead of force-unwrap crashing the app
        return SupabaseClient(
            supabaseURL: URL(string: "http://localhost:54321")!,
            supabaseKey: "placeholder"
        )
    }
    return SupabaseClient(
        supabaseURL: url,
        supabaseKey: AppConstants.supabaseAnonKey
    )
}()
