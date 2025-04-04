describe('DCAT Extension', () => {
    const orgId = "org-" + cy.helpers.randomSlug();
    const packageId = "dataset-" + orgId;

    before(() => {
      cy.login();
      cy.create_token();
      cy.create_organization(orgId);
      cy.create_dataset({
        "name": packageId,
        "owner_org": orgId,
      });
    });

    after(() => {
      cy.delete_dataset(packageId);
      cy.delete_organization(orgId);
    });

    it('Datasets have an rdf endpoint', () => {
        cy.request(`/dataset/${packageId}.rdf`).should((response) => {
            expect(response.status).to.eq(200);
            expect(response.body).to.contain('dcat:Dataset');
        });
    });
});
