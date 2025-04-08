const group = {
    name: `climate-${cy.helpers.randomSlug()}`,
    desc: `Climate Group ${cy.helpers.randomSlug()}`
}
let orgId = `org-${cy.helpers.randomSlug()}`;
let packageId = `package-${orgId}`;

describe('Group', () => {
    before(() => {
        cy.login();
        cy.create_token();
        cy.create_organization(orgId);
        cy.create_dataset({"name": packageId, "owner_org": orgId});
        cy.create_group(group.name, group.desc);
    });

    after(() => {
        cy.delete_group(group.name);
        cy.delete_dataset(packageId);
        cy.delete_organization(orgId);
        cy.revoke_token();
        cy.logout();
    });

    it('Can put a package in a group', () => {
        cy.request({
            url: '/api/action/package_patch',
            method: 'POST',
            body: {
                id: packageId,
                groups: [{ name: group.name }],
            },
        }).should((response) => {
            expect(response.body).to.have.property('success', true);
            expect(response.body.result.groups[0]).to.have.property('name', group.name);
        });
    });
});
