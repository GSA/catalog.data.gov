describe('Spatial', () => {
    it('Can search geographies by name', () => {
        cy.request('/api/3/action/location_search?q=california').should((response) => {
            expect(response.body).to.have.property('success', true);
            expect(response.body.result[0]).to.have.property('text', 'California');
        });
    });
    it('Can put a package in an organization', () => {
        const group_name = 'climate';
        cy.logout();
        cy.login();
        cy.delete_group(group_name);
        cy.create_group(group_name, "Climate Group");
        cy.request({
            url: '/api/action/package_patch',
            method: 'POST',
            body: {
                "id": "nefsc-2000-spring-bottom-trawl-survey-al0002-ek500",
                "groups": [{"name": group_name}]
            }
        }).should((response) => {
            expect(response.body).to.have.property('success', true);
            expect(response.body.result.groups[0]).to.have.property("name", "climate");

            // Cleanup
            cy.delete_group(group_name);
            cy.logout();
        })
    })
});