export const useBankInfo = () => {
    const supabase = useSupabaseClient()
    const { organizationId } = useOrganization()

    const bankAccounts = ref<any[]>([])
    const loading = ref(false)

    const fetchBankAccounts = async () => {
        if (!organizationId.value) return

        loading.value = true
        const { data, error } = await supabase.schema('app_carelink')
            .from('bank_accounts')
            .select('*')
            .eq('organization_id', organizationId.value)
            .eq('active', true) // Solo cuentas activas
            .order('created_at', { ascending: false })

        // Fallback: si falla por columna 'active' (si no existe), intentamos traer todo
        if (error && error.code === '42703') { // Undefined column
            const { data: retryData } = await supabase.schema('app_carelink')
                .from('bank_accounts')
                .select('*')
                .eq('organization_id', organizationId.value)

            bankAccounts.value = retryData || []
        } else {
            bankAccounts.value = data || []
        }

        loading.value = false
    }

    return {
        bankAccounts,
        loading,
        fetchBankAccounts
    }
}
