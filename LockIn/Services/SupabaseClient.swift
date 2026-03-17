import Foundation
import Supabase

/// Global Supabase client instance. Configure URL and key in Constants.swift.
let supabase = SupabaseClient(
    supabaseURL: URL(string: AppConstants.supabaseURL)!,
    supabaseKey: AppConstants.supabaseAnonKey
)
