module MultipleClaimsPresenter
  def self.present(claim, claimant:, lead_claimant: false)
    if lead_claimant
      ::ApplicationController.render(template: 'export_multiple_claims_service/lead_claimant_data.json.jbuilder', locals: { claim: claim, claimant: claimant, lead_claimant: lead_claimant })
    else
      ::ApplicationController.render(template: 'export_multiple_claims_service/secondary_claimant_data.json.jbuilder', locals: { claim: claim, claimant: claimant, lead_claimant: lead_claimant })
    end
  end
end