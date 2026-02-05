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

        try {
            console.log('Fetching profile for UUID:', currentUser.id);
            const { data, error } = await client
                .from('profiles')
                .select('*, organizations(*)')
                .eq('id', currentUser.id)
                .single();

            if (error) {
                console.error('Error fetching profile:', error);
                throw error;
            }

            if (data) {
                profile.value = data;
                console.log('Profile loaded:', data.role);
            }
            return data;
        } catch (e) {
            console.error('Fetch Profile Exception:', e);
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
