require 'rails_helper'
RSpec.describe "create claim multiples" do
  subject(:worker) { ::EtExporter::ExportClaimWorker }
  subject(:multiples_worker) { ::ExportMultiplesWorker }
  let(:test_ccd_client) { EtCcdClient::UiClient.new.tap { |c| c.login(username: 'm@m.com', password: 'Pa55word11') } }
  include_context 'with stubbed ccd'

  before do
    stub_request(:get, "http://dummy.com/examplepdf").
      to_return(status: 200, body: File.new(File.absolute_path('../fixtures/chloe_goodwin.pdf', __dir__)), headers: { 'Content-Type' => 'application/pdf'})
    stub_request(:get, "http://dummy.com/examplecsv").
      to_return(status: 200, body: File.new(File.absolute_path('../fixtures/example.csv', __dir__)), headers: { 'Content-Type' => 'text/csv'})
  end

  it 'creates a multiples claim referencing many single claims in ccd' do
    # Arrange - Produce the input JSON
    export = build(:export, :for_claim, claim_traits: [:default_multiple_claimants])

    # Act - Call the worker in the same way the application would (minus using redis)
    worker.perform_async(export.as_json.to_json)
    Sidekiq::Worker.drain_all

    # Assert - After calling all of our workers like sidekiq would, check with CCD (or fake CCD) to see what we sent
    ccd_case = test_ccd_client.caseworker_search_latest_by_multiple_reference(export.resource.reference, case_type_id: 'Manchester_Multiples_Dev')
    aggregate_failures 'validating key fields' do
      expect(ccd_case['case_fields']).to include 'multipleReference' => export.resource.reference
      case_references = ccd_case.dig('case_fields', 'caseIdCollection').map { |obj| obj.dig('value', 'ethos_CaseReference') }
      expect(case_references.length).to eql(export.resource.secondary_claimants.length + 1)
      expect(case_references).to all be_an_instance_of(String)
    end
  end

  it 'creates many single claims all with status of Pending' do
    # Arrange - Produce the input JSON
    export = build(:export, :for_claim, claim_traits: [:default_multiple_claimants])

    # Act - Call the worker in the same way the application would (minus using redis)
    worker.perform_async(export.as_json.to_json)
    Sidekiq::Worker.drain_all

    # Assert - After calling all of our workers like sidekiq would, check with CCD (or fake CCD) to see what we sent
    ccd_case = test_ccd_client.caseworker_search_latest_by_multiple_reference(export.resource.reference, case_type_id: 'Manchester_Multiples_Dev')
    case_references = ccd_case.dig('case_fields', 'caseIdCollection').map { |obj| obj.dig('value', 'ethos_CaseReference') }
    aggregate_failures 'validating key fields' do
      case_references.each do |ref|
        created_case = test_ccd_client.caseworker_search_latest_by_ethos_case_reference(ref, case_type_id: 'Manchester_Dev')
        expect(created_case['case_fields']).to include 'state' => 'Pending'
      end
    end
  end

  it 'has the primary claimant first when the jobs are processed in order' do
    # Arrange - Produce the input JSON
    export = build(:export, :for_claim, claim_traits: [:default_multiple_claimants])

    # Act - Call the worker in the same way the application would (minus using redis)
    worker.perform_async(export.as_json.to_json)
    Sidekiq::Worker.drain_all

    # Assert - After calling all of our workers like sidekiq would, check with CCD (or fake CCD) to see what we sent
    primary_claimant=export.resource.primary_claimant
    ccd_case = test_ccd_client.caseworker_search_latest_by_multiple_reference(export.resource.reference, case_type_id: 'Manchester_Multiples_Dev')
    case_references = ccd_case.dig('case_fields', 'caseIdCollection').map { |obj| obj.dig('value', 'ethos_CaseReference') }
    aggregate_failures 'validating key fields' do
      created_case = test_ccd_client.caseworker_search_latest_by_ethos_case_reference(case_references.first, case_type_id: 'Manchester_Dev')
      expect(created_case['case_fields']).to include \
        'claimantIndType' => a_hash_including(
        'claimant_title1' => primary_claimant.title,
        'claimant_first_names' => primary_claimant.first_name,
        'claimant_last_name' => primary_claimant.last_name
      )
    end
  end

  it 'has the primary claimant first when the jobs are processed in reverse order' do
    # Arrange - Produce the input JSON
    export = build(:export, :for_claim, claim_traits: [:default_multiple_claimants])

    # Act - Call the worker in the same way the application would (minus using redis)
    worker.perform_async(export.as_json.to_json)

    ::EtExporter::ExportClaimWorker.drain
    ExportMultiplesWorker.jobs.reverse!
    Sidekiq::Worker.drain_all

    # Assert - After calling all of our workers like sidekiq would, check with CCD (or fake CCD) to see what we sent
    primary_claimant=export.resource.primary_claimant
    ccd_case = test_ccd_client.caseworker_search_latest_by_multiple_reference(export.resource.reference, case_type_id: 'Manchester_Multiples_Dev')
    case_references = ccd_case.dig('case_fields', 'caseIdCollection').map { |obj| obj.dig('value', 'ethos_CaseReference') }
    aggregate_failures 'validating key fields' do
      created_case = test_ccd_client.caseworker_search_latest_by_ethos_case_reference(case_references.first, case_type_id: 'Manchester_Dev')
      expect(created_case['case_fields']).to include \
        'claimantIndType' => a_hash_including(
        'claimant_title1' => primary_claimant.title,
        'claimant_first_names' => primary_claimant.first_name,
        'claimant_last_name' => primary_claimant.last_name
      )
    end
  end

  # it 'creates a claim in ccd that matches the schema' do
  #   boom!
  #   # Arrange - Produce the input JSON
  #   export = build(:export, :for_claim)
  #
  #   # Act - Call the worker in the same way the application would (minus using redis)
  #   worker.perform_async(export.as_json.to_json)
  #   worker.drain
  #
  #   # Assert - Check with CCD (or fake CCD) to see what we sent
  #   ccd_case = test_ccd_client.caseworker_search_latest_by_reference(export.resource.reference, case_type_id: 'Manchester_Dev')
  #   expect(ccd_case['case_fields']).to match_json_schema('case_create')
  # end
  #
  # it 'populates the claimant data correctly with an address specifying UK country' do
  #   boom!
  #   # Arrange - Produce the input JSON
  #   claimant = build(:claimant, :default, address: build(:address, :with_uk_country))
  #   export = build(:export, :for_claim, resource: build(:claim, :default, primary_claimant: claimant))
  #
  #   # Act - Call the worker in the same way the application would (minus using redis)
  #   worker.perform_async(export.as_json.to_json)
  #   worker.drain
  #
  #   # Assert - Check with CCD (or fake CCD) to see what we sent
  #   ccd_case = test_ccd_client.caseworker_search_latest_by_reference(export.resource.reference, case_type_id: 'Manchester_Dev')
  #   ccd_claimant = ccd_case.dig('case_fields', 'claimantType')
  #   expect(ccd_claimant).to include "claimant_phone_number" => claimant.address_telephone_number,
  #                                   "claimant_mobile_number" => claimant.mobile_number,
  #                                   "claimant_email_address" => claimant.email_address,
  #                                   "claimant_contact_preference" => claimant.contact_preference.titleize,
  #                                   "claimant_addressUK" => {
  #                                       "AddressLine1" => claimant.address.building,
  #                                       "AddressLine2" => claimant.address.street,
  #                                       "PostTown" => claimant.address.locality,
  #                                       "County" => claimant.address.county,
  #                                       "PostCode" => claimant.address.post_code,
  #                                       "Country" => claimant.address.country
  #                                   }
  # end
  #
  # it 'populates the claimant data correctly with an address specifying Non UK country (country should be nil)' do
  #   boom!
  #
  #   # Arrange - Produce the input JSON
  #   claimant = build(:claimant, :default, address: build(:address, :with_other_country))
  #   export = build(:export, :for_claim, resource: build(:claim, :default, primary_claimant: claimant))
  #
  #   # Act - Call the worker in the same way the application would (minus using redis)
  #   worker.perform_async(export.as_json.to_json)
  #   worker.drain
  #
  #   # Assert - Check with CCD (or fake CCD) to see what we sent
  #   ccd_case = test_ccd_client.caseworker_search_latest_by_reference(export.resource.reference, case_type_id: 'Manchester_Dev')
  #   ccd_claimant = ccd_case.dig('case_fields', 'claimantType')
  #   expect(ccd_claimant).to include "claimant_phone_number" => claimant.address_telephone_number,
  #                                   "claimant_mobile_number" => claimant.mobile_number,
  #                                   "claimant_email_address" => claimant.email_address,
  #                                   "claimant_contact_preference" => claimant.contact_preference.titleize,
  #                                   "claimant_addressUK" => {
  #                                       "AddressLine1" => claimant.address.building,
  #                                       "AddressLine2" => claimant.address.street,
  #                                       "PostTown" => claimant.address.locality,
  #                                       "County" => claimant.address.county,
  #                                       "PostCode" => claimant.address.post_code,
  #                                       "Country" => nil
  #                                   }
  # end
  #
  # it 'populates the claimant data correctly with an address without any country in the input data (backward compatibility)' do
  #   # Arrange - Produce the input JSON
  #   boom!
  #   claimant = build(:claimant, :default, address: build(:address))
  #   export = build(:export, :for_claim, resource: build(:claim, :default, primary_claimant: claimant))
  #
  #   # Act - Call the worker in the same way the application would (minus using redis)
  #   worker.perform_async(export.as_json.to_json)
  #   worker.drain
  #
  #   # Assert - Check with CCD (or fake CCD) to see what we sent
  #   ccd_case = test_ccd_client.caseworker_search_latest_by_reference(export.resource.reference, case_type_id: 'Manchester_Dev')
  #   ccd_claimant = ccd_case.dig('case_fields', 'claimantType')
  #   expect(ccd_claimant).to include "claimant_phone_number" => claimant.address_telephone_number,
  #                                   "claimant_mobile_number" => claimant.mobile_number,
  #                                   "claimant_email_address" => claimant.email_address,
  #                                   "claimant_contact_preference" => claimant.contact_preference.titleize,
  #                                   "claimant_addressUK" => {
  #                                       "AddressLine1" => claimant.address.building,
  #                                       "AddressLine2" => claimant.address.street,
  #                                       "PostTown" => claimant.address.locality,
  #                                       "County" => claimant.address.county,
  #                                       "PostCode" => claimant.address.post_code,
  #                                       "Country" => nil
  #                                   }
  # end
  it 'populates the documents collection correctly with a pdf file and a csv file input' do
    # Arrange - Produce the input JSON
    export = build(:export, :for_claim, claim_traits: [:default_multiple_claimants])
    claimant = export.dig('resource', 'primary_claimant')

    # Act - Call the worker in the same way the application would (minus using redis)
    worker.perform_async(export.as_json.to_json)
    Sidekiq::Worker.drain_all

    # Assert - Check with CCD (or fake CCD) to see what we sent
    header_case = test_ccd_client.caseworker_search_latest_by_multiple_reference(export.resource.reference, case_type_id: 'Manchester_Multiples_Dev')
    case_references = header_case.dig('case_fields', 'caseIdCollection').map { |obj| obj.dig('value', 'ethos_CaseReference') }
    ccd_case = test_ccd_client.caseworker_search_latest_by_ethos_case_reference(case_references.first, case_type_id: 'Manchester_Dev')

    ccd_documents = ccd_case.dig('case_fields', 'documentCollection')
    expect(ccd_documents).to \
      contain_exactly \
        a_hash_including('id' => nil,
                         'value' => a_hash_including(
                           'typeOfDocument' => 'Application',
                           'shortDescription' => "ET1 application for #{claimant.first_name} #{claimant.last_name}",
                           'uploadedDocument' => a_hash_including(
                             'document_url' => an_instance_of(String),
                             'document_binary_url' => an_instance_of(String),
                             'document_filename' => 'et1_chloe_goodwin.pdf'
                           )
                         )),
        a_hash_including('id' => nil,
                         'value' => a_hash_including(
                           'typeOfDocument' => 'Other',
                           'shortDescription' => "Additional claimants file for #{claimant.first_name} #{claimant.last_name}",
                           'uploadedDocument' => a_hash_including(
                             'document_url' => an_instance_of(String),
                             'document_binary_url' => an_instance_of(String),
                             'document_filename' => 'et1a_first_last.csv'
                           )
                         ))
  end

end
