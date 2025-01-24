describe('Prepare', { testIsolation: false }, () => {
    const testOrgName = 'Test Organization';
    const testOrgId = 'test-organization';
    const testOrgDesc = 'cypress test org description';

    before(() => {
        /**
         * Login as cypress user and create an organization
         */
        cy.login();
        cy.create_token();

        // Create the Test Organization using UI
        // We can use the API to create the organization, but we want to test the UI
        // expecially the js part to create the testOrgId from the testOrgName
        cy.visit('/organization');
        cy.get('a[class="btn btn-primary"]').click();
        cy.create_organization_ui(testOrgName, testOrgDesc);
        cy.logout();

        // Create the Test Dataset
        cy.create_dataset();
    });

    after(() => {
        cy.delete_dataset();
        cy.delete_organization();
        cy.revoke_token();
        cy.logout();
    });

    it('Test Org is present', () => {
        // can visit the org using testOrgId 
        cy.visit('/organization/' + testOrgId);
        cy.contains(testOrgName);
        cy.contains(testOrgDesc);
    });

    it('Test Dataset is present', () => {
        cy.visit('/dataset/test-dataset');
        cy.contains('Test Dataset');
    });
});
