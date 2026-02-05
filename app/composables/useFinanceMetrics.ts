/**
 * Composable for calculating finance metrics including:
 * - Balance breakdown (regular vs eventual)
 * - Pending needs valuation
 * - Savings from in-kind donations
 */
export const useFinanceMetrics = () => {
    const supabase = useSupabaseClient()
    const { organizationId } = useOrganization()

    /**
     * Fetch pending needs with their estimated costs
     * Returns total estimated cost of approved but unfulfilled requests
     */
    const fetchPendingNeedsValue = async (): Promise<number> => {
        if (!organizationId.value) return 0

        // Get approved requests
        const { data: requests } = await supabase.schema('app_carelink')
            .from('requests')
            .select('id, quantity, estimated_unit_cost')
            .eq('organization_id', organizationId.value)
            .eq('status', 'APROBADO')

        if (!requests || requests.length === 0) return 0

        // Get fulfillments for these requests
        const requestIds = requests.map(r => r.id)
        const { data: fulfillments } = await supabase.schema('app_carelink')
            .from('fulfillments')
            .select('request_id, quantity')
            .in('request_id', requestIds)
            .neq('status', 'CANCELADO')

        // Calculate remaining unfulfilled value
        let totalPendingValue = 0

        for (const req of requests) {
            const unitCost = Number(req.estimated_unit_cost) || 0
            const totalQty = Number(req.quantity) || 0

            // Sum fulfilled quantity for this request
            const fulfilledQty = (fulfillments || [])
                .filter(f => f.request_id === req.id)
                .reduce((sum, f) => sum + (Number(f.quantity) || 0), 0)

            const remainingQty = Math.max(0, totalQty - fulfilledQty)
            totalPendingValue += remainingQty * unitCost
        }

        return totalPendingValue
    }

    /**
     * Calculate the monetary value of in-kind donations (savings)
     * This is based on fulfilled requests that would have been purchased
     */
    const fetchDonationSavings = async (): Promise<number> => {
        if (!organizationId.value) return 0

        // Get requests that have fulfillments
        const { data: requests } = await supabase.schema('app_carelink')
            .from('requests')
            .select('id, quantity, estimated_unit_cost')
            .eq('organization_id', organizationId.value)
            .gt('estimated_unit_cost', 0) // Only count those with estimated cost

        if (!requests || requests.length === 0) return 0

        const requestIds = requests.map(r => r.id)
        const { data: fulfillments } = await supabase.schema('app_carelink')
            .from('fulfillments')
            .select('request_id, quantity, status')
            .in('request_id', requestIds)
            .in('status', ['ENTREGADO', 'PENDIENTE', 'COMPROMETIDO']) // Count all non-cancelled

        if (!fulfillments || fulfillments.length === 0) return 0

        // Calculate savings (fulfilled qty * unit cost)
        let totalSavings = 0

        for (const req of requests) {
            const unitCost = Number(req.estimated_unit_cost) || 0

            const fulfilledQty = fulfillments
                .filter(f => f.request_id === req.id)
                .reduce((sum, f) => sum + (Number(f.quantity) || 0), 0)

            totalSavings += fulfilledQty * unitCost
        }

        return totalSavings
    }

    /**
     * Fetch finance categories for dropdowns
     */
    const fetchCategories = async () => {
        const { data } = await supabase.schema('app_carelink')
            .from('finance_categories')
            .select('*')
            .order('sort_order')

        return data || []
    }

    /**
     * Calculate complete balance metrics for a given month
     */
    const calculateMonthlyBalance = (records: any[]) => {
        let regularIncome = 0
        let eventualIncome = 0
        let regularExpense = 0
        let eventualExpense = 0

        records.forEach(r => {
            const val = Number(r.amount) || 0
            const isIncome = r.type === 'INGRESO' || r.type === 'IN'
            const isRegular = r.frequency === 'REGULAR'

            if (isIncome) {
                if (isRegular) regularIncome += val
                else eventualIncome += val
            } else {
                if (isRegular) regularExpense += val
                else eventualExpense += val
            }
        })

        return {
            regularIncome,
            eventualIncome,
            regularExpense,
            eventualExpense,
            totalIncome: regularIncome + eventualIncome,
            totalExpense: regularExpense + eventualExpense,
            operational: regularIncome - regularExpense,
            net: (regularIncome + eventualIncome) - (regularExpense + eventualExpense)
        }
    }

    return {
        fetchPendingNeedsValue,
        fetchDonationSavings,
        fetchCategories,
        calculateMonthlyBalance
    }
}
