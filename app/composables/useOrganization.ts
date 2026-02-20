export const useOrganization = () => {
    const client = useSupabaseClient();
    const user = useSupabaseUser();

    // Use useState for global state across components
    const profile = useState<any>('user_profile', () => null);
    const loading = useState<boolean>('profile_loading', () => false);

    const fetchProfile = async () => {
        let currentUser = user.value;

        // Fallback: If user ref is empty or missing ID, try fetching from auth session explicitly
        if (!currentUser || !currentUser.id) {
            const { data } = await client.auth.getUser();
            if (data.user) {
                currentUser = data.user;
            }
        }

        if (!currentUser || !currentUser.id) {
            // Still no user? Then we are truly not logged in or session is invalid
            console.warn('fetchProfile: No valid session found.');
            return null;
        }

        loading.value = true;

        const logout = async () => {
            profile.value = null;
            await client.auth.signOut();
            return navigateTo('/login');
        };

        try {
            console.log('Fetching profile for UUID:', currentUser.id);
            // Explicitly use the schema to avoid any ambiguity or race conditions with plugins
            const { data, error } = await (client as any)
                .schema('app_carelink')
                .from('profiles')
                .select('*, organizations(*)')
                .eq('id', currentUser.id)
                .single();

            if (error) {
                console.error('[useOrganization] Error fetching profile:', {
                    message: error.message,
                    details: error.details,
                    hint: error.hint,
                    code: error.code
                });

                // If we have a user but CANNOT fetch the profile (e.g. 406 Not Acceptable, RLS policies, 
                // or user deleted from profiles but not auth), we should probably logout to clean the state.
                // We check specifically for PGRST116 (0 rows) or 406/401.
                if (error.code === 'PGRST116' || error.message.includes('JSON')) {
                    console.warn('Profile not found/Ghost session detected. Logging out...');
                    await logout();
                    return null;
                }

                await logout();
                return null;
            }

            if (data) {
                profile.value = data;
                console.log('Profile loaded:', data.role);
            } else {
                console.warn('[useOrganization] No data returned for profile');
                await logout();
                return null;
            }
            return data;
        } catch (e) {
            console.error('Fetch Profile Exception:', e);
            // await logout(); // Careful with infinite loops if navigateTo fails
            return null;
        } finally {
            loading.value = false;
        }
    };

    const organizationId = computed(() => profile.value?.organization_id);
    const organizationName = computed(() => profile.value?.organizations?.name);

    return {
        profile,
        loading,
        organizationId,
        organizationName,
        fetchProfile
    };
};
